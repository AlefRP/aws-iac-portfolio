resource "aws_athena_workgroup" "this" {
  name = var.name

  configuration {
    enforce_workgroup_configuration    = var.enforce_workgroup_configuration
    publish_cloudwatch_metrics_enabled = var.publish_cloudwatch_metrics
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query

    result_configuration {
      output_location = "s3://${var.results_bucket}/${var.results_prefix}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = var.tags
}
