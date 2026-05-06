variable "name" {
  description = "Crawler name"
  type        = string
}

variable "database_name" {
  description = "Glue catalog database where tables will be created"
  type        = string
}

variable "s3_targets" {
  description = "List of S3 paths to crawl (e.g. s3://bucket/raw/)"
  type        = list(string)
}

variable "table_prefix" {
  description = "Prefix added to table names"
  type        = string
  default     = ""
}

variable "schedule" {
  description = "Cron expression for the crawler. If null, runs on demand only"
  type        = string
  default     = null
}

variable "bucket_arns" {
  description = "ARNs of the buckets the crawler must read"
  type        = list(string)
}

variable "configuration" {
  description = "JSON crawler configuration (e.g. CombineCompatibleSchemas)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the crawler resources"
  type        = map(string)
  default     = {}
}
