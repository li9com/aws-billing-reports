#!/bin/bash
set -e
if [[ -z $REPORT_INTERVAL_DAYS || -z $AWS_BILLING_BUCKET || -z $AWS_ACCOUNT_ID || -z $EMAIL_FROM || -z $EMAIL_TO || -z $AZURE_BILLING_CONTAINER || -z $AZURE_STORAGE_CONNECTION_STRING ]]; then
  echo 'The following env variables MUST be defined: REPORT_INTERVAL_DAYS, AWS_BILLING_BUCKET, AWS_ACCOUNT_ID, EMAIL_FROM, EMAIL_TO, AZURE_BILLING_CONTAINER, AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_CONNECTION_STRING'
  exit 1
fi

# Export env variables
export REPORT_INTERVAL_DAYS
export AZURE_STORAGE_CONNECTION_STRING

# The following zip archive with billing report must be present in AWS_BILLING_BUCKET
REPORT_ZIP=${AWS_ACCOUNT_ID}-aws-billing-detailed-line-items-with-resources-and-tags-$(date +'%Y-%m').csv.zip
MYSQL_CONN="-uroot -pmysql -h127.0.0.1"


# Wait for MySQL to become ready
while ! mysql $MYSQL_CONN -e "show databases" 2>/dev/null ; do
  echo "waiting for mysql"; sleep 10;
done

# Downloading AWS billing report
aws s3 cp s3://${AWS_BILLING_BUCKET}/${REPORT_ZIP} .
unzip -p $REPORT_ZIP | head -n -12 > aws-report.csv

# Downloading Azure billing report
FILE=$(az storage blob list -c "${AZURE_BILLING_CONTAINER}" -o tsv --query "sort_by([].{Name:name, last:properties.lastModified} &last)" | tail -1 | awk '{print $1}')
az storage blob download -c "${AZURE_BILLING_CONTAINER}" --name "${FILE}" -f azure-report.csv

# Load AWS and Azure report SQL schema into MySQL
if head -1 aws-report.csv | grep -q "aws:cloudformation:stack-name"; then
  # if AWS report contains column "aws:cloudformation:stack-name"
  mysql $MYSQL_CONN test < aws-schema.sql
else
  # if not contains column "aws:cloudformation:stack-name"
  mysql $MYSQL_CONN test < aws-schema-1.sql
fi
mysql $MYSQL_CONN test < azure-schema.sql

# Load billing report into MySQL
mysqlimport $MYSQL_CONN --fields-terminated-by ',' --fields-enclosed-by '"' --ignore-lines 1 --replace --local test aws-report.csv
mysqlimport $MYSQL_CONN --fields-terminated-by ',' --fields-enclosed-by '"' --ignore-lines 1 --replace --local test azure-report.csv

# Run queries
envsubst < aws-queries.sql | mysql -t $MYSQL_CONN test > aws-result.txt
envsubst < azure-queries.sql | mysql -t $MYSQL_CONN test > azure-result.txt

# AWS SES works in us-east-1 and us-west-2 only
aws --region us-east-1 ses send-email --from "$EMAIL_FROM" --destination "ToAddresses=$EMAIL_TO" --subject "AWS billing report" --text file://aws-result.txt
aws --region us-east-1 ses send-email --from "$EMAIL_FROM" --destination "ToAddresses=$EMAIL_TO" --subject "Azure billing report" --text file://azure-result.txt
