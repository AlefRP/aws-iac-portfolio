variable "name" {
  description = "Glue catalog database name"
  type        = string
}

variable "description" {
  description = "Database description"
  type        = string
  default     = null
}

variable "location_uri" {
  description = "S3 URI used as default location for tables in the database"
  type        = string
  default     = null
}
