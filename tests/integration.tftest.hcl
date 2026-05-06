mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-east-1:123456789012:function:mock-fn"
      function_name = "mock-fn"
    }
  }
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/mock-rule"
    }
  }
}
mock_provider "archive" {}

variables {
  data_bucket_name           = "integration-data-bucket-2026"
  athena_results_bucket_name = "integration-athena-results-2026"
  environment                = "dev"
  aws_region                 = "us-east-1"
  aws_profile                = "default"
  project_name               = "test-data"
  tickers                    = ["AAPL", "MSFT"]
  lambda_schedule            = "cron(0 6 * * ? *)"
}

run "data_platform_plans_successfully" {
  command = plan

  assert {
    condition     = module.collector_lambda.function_name == "test-data-yahoo-finance-collector"
    error_message = "Lambda name should follow project naming convention"
  }

  assert {
    condition     = module.glue_database.name == "test_data_dev"
    error_message = "Glue database should use snake_case from project + environment"
  }

  assert {
    condition     = module.athena.name == "test-data-dev"
    error_message = "Athena workgroup name should be project-environment"
  }
}

run "lambda_has_yahoo_environment_variables" {
  command = plan

  assert {
    condition     = module.collector_lambda.function_name == "test-data-yahoo-finance-collector"
    error_message = "Lambda should be created"
  }

  assert {
    condition     = local.raw_prefix == "raw/yahoo_finance"
    error_message = "Raw prefix must be raw/yahoo_finance"
  }
}

run "glue_paths_are_consistent" {
  command = apply

  assert {
    condition     = startswith(local.raw_path, "s3://")
    error_message = "Raw path should be an S3 URI"
  }

  assert {
    condition     = startswith(local.curated_path, "s3://")
    error_message = "Curated path should be an S3 URI"
  }

  assert {
    condition     = endswith(local.raw_path, "/raw/yahoo_finance/")
    error_message = "Raw path must point at raw/yahoo_finance/"
  }

  assert {
    condition     = endswith(local.curated_path, "/curated/stocks/")
    error_message = "Curated path must point at curated/stocks/"
  }
}

run "two_buckets_are_provisioned" {
  command = apply

  assert {
    condition     = module.data_bucket.bucket_id != module.athena_results_bucket.bucket_id
    error_message = "Data bucket and Athena results bucket must be different"
  }
}

run "tickers_are_propagated" {
  command = plan

  variables {
    tickers = ["PETR4.SA", "VALE3.SA", "ITUB4.SA"]
  }

  assert {
    condition     = local.common_tags["Environment"] == "dev"
    error_message = "Environment tag should be propagated"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [
    var.environment,
  ]
}
