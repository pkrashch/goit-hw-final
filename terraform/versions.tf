terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}

# AWS Budgets and Cost Explorer APIs live in us-east-1 only for some calls;
# aws_budgets_budget works from any region, so no alias is required.
data "aws_availability_zones" "available" {
  state = "available"
}
