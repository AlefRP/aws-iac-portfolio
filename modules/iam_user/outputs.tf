output "user_arn" {
  description = "IAM user ARN"
  value       = aws_iam_user.this.arn
}

output "user_name" {
  description = "IAM user name"
  value       = aws_iam_user.this.name
}

output "user_id" {
  description = "Unique IAM user ID"
  value       = aws_iam_user.this.unique_id
}

output "access_key_id" {
  description = "Access key ID (only when create_access_key is true)"
  value       = try(aws_iam_access_key.this[0].id, null)
}

output "access_key_secret" {
  description = "Access key secret (only when create_access_key is true). Sensitive."
  value       = try(aws_iam_access_key.this[0].secret, null)
  sensitive   = true
}
