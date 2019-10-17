provider "aws" {
  region  = "us-east-2"
  profile = "li9"
}

module "billingreport" {
  source               = "./tfmodules/billingreport"
  account_id           = "${var.account_id}"
  ecs_task_role        = "${var.ecs_task_role}"
  ecs_events_role      = "${var.ecs_events_role}"
  ecs_execution_role   = "${var.ecs_execution_role}"
  ecs_docker_image     = "${var.ecs_docker_image}"
  email                = "${var.email}"
  billing_bucket       = "${var.billing_bucket}"
  report_interval_days = "${var.report_interval_days}"
  reporting_schedule   = "${var.reporting_schedule}"
  subnets              = "${var.subnets}"
}
