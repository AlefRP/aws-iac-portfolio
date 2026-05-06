variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "source_dir" {
  description = "Local directory with the Lambda source code (will be zipped)"
  type        = string
}

variable "handler" {
  description = "Handler entrypoint (file.function)"
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Memory in MB"
  type        = number
  default     = 256
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "additional_policy_statements" {
  description = "Extra IAM statements to attach to the execution role"
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g. cron(0 6 * * ? *)). If null, no schedule is created"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags applied to the Lambda resources"
  type        = map(string)
  default     = {}
}
