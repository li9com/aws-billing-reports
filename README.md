# aws-billing-reports
Sending AWS billing reports to email

This reposiory contains code necessary process AWS billing reports and send result to email addresses.
Solution consists of the following pieces:
1) AWS Elastic CS Fargate task that runs two Docker containers regularly using CloudWatch cron task.
2) First container is simple MySQL database
3) Second one is bash script that loads billing report CSV file from S3 bucket, uploads it into MySQL, performs some queries and emails the result through AWS Simple Email Service (SES).

Terraform code contains IAM Role, ECS cluster, task definition and CloudWatch cron task. Terraform code is done as single TF module (./tfmodules/billingreport/).

Docker folder contains:
1) schema.sql - this is SQL schema derived from billing report CSV file.
2) queries.sql - these are SQL queries that generate the resulting report.
3) entrypoint.sh - this is a script that runs everything inside Docker container.

In order to create report:
1) Create Docker image from docker folder and upload it to registry (preferrably ECR).
2) Examine variables.tf and create terraform.tfvars file with necessary variables.
3) Run terraform.
