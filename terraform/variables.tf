variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "project" {
  type    = string
  default = "goit-final"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "single_nat_gateway" {
  description = "One shared NAT (cheaper) vs one per AZ (highly available)."
  type        = bool
  default     = true
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 6
}

variable "cpu_target" {
  description = "Target average CPU % for target-tracking scaling."
  type        = number
  default     = 50
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "alert_email" {
  description = "E-mail that receives SNS alarm and budget notifications."
  type        = string
}

variable "monthly_budget_usd" {
  type    = number
  default = 50
}

variable "existing_anomaly_monitor_arn" {
  description = "ARN of an existing Cost Anomaly monitor (AWS allows one SERVICE monitor per account). Empty = create one."
  type        = string
  default     = ""
}
