output "bucket_id" {
  description = "Name of the S3 bucket"
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_bucket.bucket_arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = module.s3_bucket.bucket_regional_domain_name
}

output "bucket_region" {
  description = "AWS region where the bucket is hosted"
  value       = module.s3_bucket.bucket_region
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = module.iam_user.user_arn
}

output "iam_user_name" {
  description = "Name of the IAM user"
  value       = module.iam_user.user_name
}
