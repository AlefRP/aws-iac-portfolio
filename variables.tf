variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Short project identifier used as prefix for resource names"
  type        = string
  default     = "tf-data"
}

variable "data_bucket_name" {
  description = "Globally unique name for the data lake S3 bucket"
  type        = string
}

variable "athena_results_bucket_name" {
  description = "Globally unique name for the Athena query results bucket"
  type        = string
}

variable "tickers" {
  description = "List of Yahoo Finance tickers to collect"
  type        = list(string)
  default = [
    "AAPL",
    "MSFT",
    "GOOGL",
    "AMZN",
    "META",
    "PETR4.SA",
    "VALE3.SA",
  ]
}

variable "yahoo_range" {
  description = "Yahoo Finance range parameter (5d, 1mo, 3mo, 1y, max)"
  type        = string
  default     = "5d"
}

variable "yahoo_interval" {
  description = "Yahoo Finance interval parameter (1d, 1wk, 1mo)"
  type        = string
  default     = "1d"
}

variable "lambda_schedule" {
  description = "EventBridge cron expression for the collector Lambda. Null = no schedule"
  type        = string
  default     = "cron(0 6 * * ? *)"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "terraform-aws-data-platform"
    ManagedBy = "terraform"
  }
}
