variable "user_name" {
  description = "IAM user name"
  type        = string

  validation {
    condition     = length(var.user_name) >= 1 && length(var.user_name) <= 64
    error_message = "User name must be between 1 and 64 characters."
  }
}

variable "path" {
  description = "Path for the IAM user"
  type        = string
  default     = "/"
}

variable "force_destroy" {
  description = "Delete user even if it has access keys, login profiles or MFA devices"
  type        = bool
  default     = false
}

variable "inline_policies" {
  description = "Map of inline policy name to JSON policy document"
  type        = map(string)
  default     = {}
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "create_access_key" {
  description = "Create an access key for the user. Only enable when programmatic access is required"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the IAM user"
  type        = map(string)
  default     = {}
}
