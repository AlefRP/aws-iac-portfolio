output "data_bucket" {
  description = "Data lake bucket name"
  value       = module.data_bucket.bucket_id
}

output "athena_results_bucket" {
  description = "Bucket for Athena query results"
  value       = module.athena_results_bucket.bucket_id
}

output "raw_path" {
  description = "S3 URI for the raw zone"
  value       = local.raw_path
}

output "curated_path" {
  description = "S3 URI for the curated zone"
  value       = local.curated_path
}

output "lambda_function_name" {
  description = "Yahoo Finance collector Lambda name"
  value       = module.collector_lambda.function_name
}

output "lambda_function_arn" {
  description = "Yahoo Finance collector Lambda ARN"
  value       = module.collector_lambda.function_arn
}

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = module.glue_database.name
}

output "raw_crawler_name" {
  description = "Glue raw zone crawler name"
  value       = module.raw_crawler.name
}

output "curated_crawler_name" {
  description = "Glue curated zone crawler name"
  value       = module.curated_crawler.name
}

output "etl_job_name" {
  description = "Glue ETL job name"
  value       = module.stocks_etl.name
}

output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = module.athena.name
}

output "athena_results_location" {
  description = "S3 URI used as Athena query results location"
  value       = module.athena.results_location
}
