output "name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.this.name
}

output "arn" {
  description = "Athena workgroup ARN"
  value       = aws_athena_workgroup.this.arn
}

output "results_location" {
  description = "S3 URI where query results are stored"
  value       = "s3://${var.results_bucket}/${var.results_prefix}"
}
