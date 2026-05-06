variable "name" {
  description = "Glue Job name"
  type        = string
}

variable "script_local_path" {
  description = "Local path to the PySpark script"
  type        = string
}

variable "scripts_bucket" {
  description = "S3 bucket where the script will be uploaded"
  type        = string
}

variable "scripts_prefix" {
  description = "Key prefix for the uploaded script"
  type        = string
  default     = "glue-scripts"
}

variable "data_bucket_arns" {
  description = "ARNs of buckets the job needs to read/write"
  type        = list(string)
}

variable "default_arguments" {
  description = "Glue default arguments passed to the job"
  type        = map(string)
  default     = {}
}

variable "glue_version" {
  description = "Glue version (4.0 = Spark 3.3 / Python 3.10)"
  type        = string
  default     = "4.0"
}

variable "worker_type" {
  description = "Worker type (G.1X, G.2X, etc)"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "timeout_minutes" {
  description = "Job timeout in minutes"
  type        = number
  default     = 30
}

variable "max_retries" {
  description = "Maximum retries on failure"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags applied to the job resources"
  type        = map(string)
  default     = {}
}
