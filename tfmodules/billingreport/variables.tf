variable "account_id" {}
variable "ecs_docker_image" {}
variable "email" { type = "map" }
variable "billing_bucket" {}
variable "report_interval_days" {}
variable "reporting_schedule" {}
variable "ecs_events_role" {}
variable "subnets" { type = "list" }
variable "azure_billing_container" {}

