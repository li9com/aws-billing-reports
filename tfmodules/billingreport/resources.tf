data "aws_region" "current" {}

resource "aws_ecs_cluster" "angapov-test" {
  name = "angapov-test"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = {
    Name = "billing-report-tasks"
  }
}

resource "aws_ecs_task_definition" "billing-reporter" {
  family                   = "billing-reporter"
  task_role_arn            = "${aws_iam_role.billing-reports.arn}"
  execution_role_arn       = "${aws_iam_role.billing-reports.arn}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions    = <<DEFINITION
[
  {
    "name": "mysql",
    "image": "mysql:5.7",
    "environment": [
      { "name": "MYSQL_DATABASE", "value": "test" },
      { "name": "MYSQL_ROOT_PASSWORD", "value": "mysql" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/billing-reporter",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "name": "billing-reporter",
    "image": "${var.ecs_docker_image}",
    "environment": [
      { "name": "AWS_ACCOUNT_ID",          "value": "${var.account_id}" },
      { "name": "AWS_BILLING_BUCKET",      "value": "${var.billing_bucket}" },
      { "name": "REPORT_INTERVAL_DAYS",    "value": "${var.report_interval_days}" },
      { "name": "EMAIL_FROM",              "value": "${var.email.from}" },
      { "name": "EMAIL_TO",                "value": "${var.email.to}" },
      { "name": "AZURE_BILLING_CONTAINER", "value": "${var.azure_billing_container}" }
    ],
    "secrets": [
      {
        "name": "AZURE_STORAGE_CONNECTION_STRING",
        "valueFrom": "${aws_secretsmanager_secret.billing-reports.arn}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/billing-reporter",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_cloudwatch_event_target" "billing-report" {
  target_id = "billing-report-ecs-cronjob"
  arn       = "${aws_ecs_cluster.angapov-test.arn}"
  rule      = "${aws_cloudwatch_event_rule.billing-reporter.name}"
  role_arn  = "arn:aws:iam::${var.account_id}:role/${var.ecs_events_role}"

  ecs_target {
    launch_type         = "FARGATE"
    task_definition_arn = "${aws_ecs_task_definition.billing-reporter.arn}"
    network_configuration {
      subnets          = "${var.subnets}"
      assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_event_rule" "billing-reporter" {
  name                = "billing-report-ecs-cronjob"
  description         = "Send billing reports by email every week"
  schedule_expression = "${var.reporting_schedule}"
}

resource "aws_secretsmanager_secret" "billing-reports" {
  name = "billing-reports"
}

resource "aws_iam_role_policy_attachment" "billing-reports" {
  role       = "${aws_iam_role.billing-reports.name}"
  policy_arn = "${aws_iam_policy.billing-reports.arn}"
}

resource "aws_iam_role" "billing-reports" {
  name = "billing-reports"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "billing-reports" {
  name        = "billing-reports"
  description = "Policy to allow getting and sending AWS billing reports by email"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::${var.billing_bucket}/*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ses:SendEmail",
              "ses:SendRawEmail"
          ],
          "Resource": "*",
          "Condition": {
              "ForAllValues:StringLike": {
                  "ses:Recipients": "*@li9.com"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "secretsmanager:GetSecretValue",
              "kms:Decrypt"
          ],
          "Resource": [
              "${aws_secretsmanager_secret.billing-reports.arn}"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": "*"
      }
  ]
}
EOF
}
