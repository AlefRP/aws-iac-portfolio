output "name" {
  description = "Crawler name"
  value       = aws_glue_crawler.this.name
}

output "arn" {
  description = "Crawler ARN"
  value       = aws_glue_crawler.this.arn
}

output "role_arn" {
  description = "Crawler IAM role ARN"
  value       = aws_iam_role.this.arn
}
