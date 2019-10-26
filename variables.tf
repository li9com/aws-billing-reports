variable "account_id" {}
variable "ecs_events_role" {}
variable "ecs_docker_image" {}
variable "billing_bucket" {}
variable "report_interval_days" {}
variable "email" { type = "map" }
variable "reporting_schedule" {}
variable "subnets" { type = "list" }
variable "azure_billing_container" {}
