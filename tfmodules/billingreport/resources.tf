variable "account_id" {}
variable "ecs_task_role" {}
variable "ecs_execution_role" {}
variable "ecs_docker_image" {}
variable "email" { type = "map" }
variable "billing_bucket" {}
variable "report_interval_days" {}
variable "reporting_schedule" {}
variable "ecs_events_role" {}
variable "subnets" { type = "list" }

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
  task_role_arn            = "arn:aws:iam::${var.account_id}:role/${var.ecs_task_role}"
  execution_role_arn       = "arn:aws:iam::${var.account_id}:role/${var.ecs_execution_role}"
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
      { "name": "ACCOUNT_ID",           "value": "${var.account_id}" },
      { "name": "BILLING_BUCKET",       "value": "${var.billing_bucket}" },
      { "name": "REPORT_INTERVAL_DAYS", "value": "${var.report_interval_days}" },
      { "name": "EMAIL_FROM",           "value": "${var.email.from}" },
      { "name": "EMAIL_TO",             "value": "${var.email.to}" },
      { "name": "EMAIL_SUBJECT",        "value": "${var.email.subject}" }
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
  role_arn  = "${var.ecs_events_role}"

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
