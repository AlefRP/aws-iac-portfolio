variable "name" {
  description = "Athena workgroup name"
  type        = string
}

variable "results_bucket" {
  description = "S3 bucket name for query results"
  type        = string
}

variable "results_prefix" {
  description = "Prefix inside the results bucket"
  type        = string
  default     = "athena-results/"
}

variable "bytes_scanned_cutoff_per_query" {
  description = "Maximum bytes that can be scanned per query (cost guardrail). Null disables it"
  type        = number
  default     = 1073741824 # 1 GB
}

variable "enforce_workgroup_configuration" {
  description = "Force queries to use this workgroup configuration"
  type        = bool
  default     = true
}

variable "publish_cloudwatch_metrics" {
  description = "Publish query metrics to CloudWatch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the workgroup"
  type        = map(string)
  default     = {}
}
