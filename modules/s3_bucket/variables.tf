variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, dots and hyphens, and start/end with letter or number."
  }
}

variable "force_destroy" {
  description = "Allow destroying the bucket even when it contains objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS. If null, SSE-S3 (AES256) is used"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules applied to the bucket"
  type = list(object({
    id                                 = string
    enabled                            = optional(bool, true)
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    abort_incomplete_multipart_days    = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the bucket"
  type        = map(string)
  default     = {}
}
