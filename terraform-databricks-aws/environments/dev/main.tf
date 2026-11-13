terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.40" }
    databricks = { source = "databricks/databricks", version = "~> 1.40" }
  }
  backend "s3" {
    bucket         = "<tfstate-bucket>"
    key            = "databricks/dev/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "<tfstate-lock-table>"
    kms_key_id     = "<kms-key-arn>"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

locals {
  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  })
}

module "dev" {
  source = "../../"

  aws_region            = var.aws_region
  aws_account_id        = var.aws_account_id
  project_name          = var.project_name
  databricks_account_id = var.databricks_account_id
  deployment_mode       = "three_vpc"

  dev_vpc_cidr              = var.dev_vpc_cidr
  dev_compute_subnet_cidrs  = var.dev_compute_subnet_cidrs
  dev_endpoint_subnet_cidrs = var.dev_endpoint_subnet_cidrs

  # TEST and PROD are not deployed in this environment config.
  # Provide placeholder values to satisfy root module variable requirements.
  test_vpc_cidr              = "10.20.0.0/16"
  test_compute_subnet_cidrs  = ["10.20.0.0/22", "10.20.4.0/22", "10.20.8.0/22"]
  test_endpoint_subnet_cidrs = ["10.20.20.0/26", "10.20.20.64/26", "10.20.20.128/26"]
  prod_vpc_cidr              = "10.30.0.0/16"
  prod_compute_subnet_cidrs  = ["10.30.0.0/22", "10.30.4.0/22", "10.30.8.0/22"]
  prod_endpoint_subnet_cidrs = ["10.30.20.0/26", "10.30.20.64/26", "10.30.20.128/26"]

  availability_zones        = var.availability_zones
  dev_root_bucket_name      = var.dev_root_bucket_name
  test_root_bucket_name     = "alfasigma-dbx-root-test-placeholder"
  prod_root_bucket_name     = "alfasigma-dbx-root-prod-placeholder"
  unity_catalog_bucket_name = var.unity_catalog_bucket_name
  uc_metastore_name         = var.uc_metastore_name

  enable_cloudtrail         = true
  enable_guardduty          = true
  enable_aws_config         = true
  enable_vpc_flow_logs      = true
  cloudwatch_retention_days = 90
  common_tags               = var.common_tags
}

variable "aws_region"            { type = string; default = "eu-west-1" }
variable "aws_account_id"        { type = string; sensitive = true }
variable "project_name"          { type = string; default = "alfasigma-dbx" }
variable "databricks_account_id" { type = string; sensitive = true }
variable "uc_metastore_name"     { type = string; default = "alfasigma-metastore" }
variable "availability_zones"    { type = list(string); default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"] }
variable "dev_vpc_cidr"          { type = string; default = "10.10.0.0/16" }
variable "dev_compute_subnet_cidrs"  { type = list(string); default = ["10.10.0.0/22", "10.10.4.0/22", "10.10.8.0/22"] }
variable "dev_endpoint_subnet_cidrs" { type = list(string); default = ["10.10.20.0/26", "10.10.20.64/26", "10.10.20.128/26"] }
variable "dev_root_bucket_name"      { type = string }
variable "unity_catalog_bucket_name" { type = string }
variable "common_tags"               { type = map(string); default = {} }
