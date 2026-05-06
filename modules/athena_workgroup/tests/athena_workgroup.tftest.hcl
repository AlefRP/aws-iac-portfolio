mock_provider "aws" {}

variables {
  name           = "test-wg"
  results_bucket = "athena-results-bucket"
}

run "creates_workgroup_with_defaults" {
  command = plan

  assert {
    condition     = aws_athena_workgroup.this.name == "test-wg"
    error_message = "Workgroup name should match input"
  }

  assert {
    condition     = one(aws_athena_workgroup.this.configuration[*].enforce_workgroup_configuration) == true
    error_message = "Default should enforce workgroup configuration"
  }

  assert {
    condition     = one(aws_athena_workgroup.this.configuration[*].publish_cloudwatch_metrics_enabled) == true
    error_message = "Default should publish CloudWatch metrics"
  }

  assert {
    condition     = one(aws_athena_workgroup.this.configuration[*].bytes_scanned_cutoff_per_query) == 1073741824
    error_message = "Default cost guardrail should be 1 GB"
  }
}

run "result_location_uses_bucket_and_prefix" {
  command = plan

  assert {
    condition     = one([for c in aws_athena_workgroup.this.configuration : one(c.result_configuration[*].output_location)]) == "s3://athena-results-bucket/athena-results/"
    error_message = "Result location should combine bucket and prefix"
  }
}

run "ssse3_encryption_is_default" {
  command = plan

  assert {
    condition     = one([for c in aws_athena_workgroup.this.configuration : one([for r in c.result_configuration : one(r.encryption_configuration[*].encryption_option)])]) == "SSE_S3"
    error_message = "Encryption option should default to SSE_S3"
  }
}
