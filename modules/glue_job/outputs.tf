output "name" {
  description = "Glue Job name"
  value       = aws_glue_job.this.name
}

output "arn" {
  description = "Glue Job ARN"
  value       = aws_glue_job.this.arn
}

output "role_arn" {
  description = "Glue Job IAM role ARN"
  value       = aws_iam_role.this.arn
}

output "script_s3_uri" {
  description = "S3 URI of the uploaded script"
  value       = "s3://${var.scripts_bucket}/${aws_s3_object.script.key}"
}
