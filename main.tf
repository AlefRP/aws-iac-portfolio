locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )

  raw_prefix     = "raw/yahoo_finance"
  curated_prefix = "curated/stocks"

  raw_path     = "s3://${module.data_bucket.bucket_id}/${local.raw_prefix}/"
  curated_path = "s3://${module.data_bucket.bucket_id}/${local.curated_prefix}/"
}

# ---------------------------------------------------------------------------
# Storage: data lake bucket + Athena query results bucket
# ---------------------------------------------------------------------------

module "data_bucket" {
  source = "./modules/s3_bucket"

  bucket_name        = var.data_bucket_name
  versioning_enabled = true
  force_destroy      = false

  lifecycle_rules = [
    {
      id                                 = "expire-old-versions"
      noncurrent_version_expiration_days = 90
      abort_incomplete_multipart_days    = 7
    }
  ]

  tags = local.common_tags
}

module "athena_results_bucket" {
  source = "./modules/s3_bucket"

  bucket_name        = var.athena_results_bucket_name
  versioning_enabled = false
  force_destroy      = true

  lifecycle_rules = [
    {
      id              = "expire-query-results"
      expiration_days = 30
    }
  ]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Lambda: Yahoo Finance collector (writes raw JSON to S3)
# ---------------------------------------------------------------------------

module "collector_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-yahoo-finance-collector"
  source_dir    = "${path.module}/lambdas/yahoo_finance_collector"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  schedule_expression = var.lambda_schedule

  environment_variables = {
    DATA_BUCKET = module.data_bucket.bucket_id
    DATA_PREFIX = local.raw_prefix
    TICKERS     = join(",", var.tickers)
    DATA_RANGE  = var.yahoo_range
    INTERVAL    = var.yahoo_interval
  }

  additional_policy_statements = [
    {
      sid       = "WriteRawObjects"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.data_bucket.bucket_arn}/${local.raw_prefix}/*"]
    }
  ]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Glue catalog database + crawlers + ETL job
# ---------------------------------------------------------------------------

module "glue_database" {
  source = "./modules/glue_database"

  name        = replace("${var.project_name}_${var.environment}", "-", "_")
  description = "Stocks data catalog (raw + curated zones)"
}

module "raw_crawler" {
  source = "./modules/glue_crawler"

  name          = "${var.project_name}-raw-crawler"
  database_name = module.glue_database.name
  s3_targets    = [local.raw_path]
  table_prefix  = "raw_"
  bucket_arns   = [module.data_bucket.bucket_arn]

  tags = local.common_tags
}

module "curated_crawler" {
  source = "./modules/glue_crawler"

  name          = "${var.project_name}-curated-crawler"
  database_name = module.glue_database.name
  s3_targets    = [local.curated_path]
  table_prefix  = "curated_"
  bucket_arns   = [module.data_bucket.bucket_arn]

  tags = local.common_tags
}

module "stocks_etl" {
  source = "./modules/glue_job"

  name              = "${var.project_name}-stocks-etl"
  script_local_path = "${path.module}/glue_scripts/stocks_etl.py"
  scripts_bucket    = module.data_bucket.bucket_id
  data_bucket_arns  = [module.data_bucket.bucket_arn]

  default_arguments = {
    "--raw_path"     = local.raw_path
    "--curated_path" = local.curated_path
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Athena workgroup using the catalog
# ---------------------------------------------------------------------------

module "athena" {
  source = "./modules/athena_workgroup"

  name           = "${var.project_name}-${var.environment}"
  results_bucket = module.athena_results_bucket.bucket_id
  results_prefix = "athena-results/"

  tags = local.common_tags
}
