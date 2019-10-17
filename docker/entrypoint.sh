#!/bin/bash
if [[ -z $REPORT_INTERVAL_DAYS || -z $BILLING_BUCKET || -z $ACCOUNT_ID || -z $EMAIL_FROM || -z $EMAIL_TO || -z $EMAIL_SUBJECT ]]; then
  echo 'The following env variables MUST be defined: REPORT_INTERVAL_DAYS, BILLING_BUCKET, ACCOUNT_ID, EMAIL_FROM, EMAIL_TO, EMAIL_SUBJECT'
  exit 1
fi

# The following zip archive with billing report must be present in BILLING_BUCKET
REPORT_ZIP=${ACCOUNT_ID}-aws-billing-detailed-line-items-with-resources-and-tags-$(date +'%Y-%m').csv.zip
MYSQL_CONN="-uroot -pmysql -h127.0.0.1"

# Export env variable for envsubst below
export REPORT_INTERVAL_DAYS

# Wait for MySQL to become ready
while ! mysql $MYSQL_CONN -e "show databases" 2>/dev/null ; do
  echo "waiting for mysql"; sleep 10;
done

# Downloading billing report
aws s3 cp s3://${BILLING_BUCKET}/${REPORT_ZIP} .

# Load report SQL schema into MySQL
mysql $MYSQL_CONN test < schema.sql

# Unzip report and remove last summary lines
unzip -p $REPORT_ZIP | head -n -9 > report.csv

# Load billing report into MySQL
mysqlimport $MYSQL_CONN --fields-terminated-by ',' --fields-enclosed-by '"' --ignore-lines 1 --replace --local test report.csv

# Run queries
envsubst < queries.sql | mysql -t $MYSQL_CONN test > result.txt

# AWS SES works in us-east-1 and us-west-2 only
aws --region us-east-1 ses send-email --from "$EMAIL_FROM" --to "$EMAIL_TO" --subject "$EMAIL_SUBJECT" --text file://result.txt
