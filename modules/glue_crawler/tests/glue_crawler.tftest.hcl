mock_provider "aws" {}

variables {
  name          = "test-crawler"
  database_name = "test_db"
  s3_targets    = ["s3://bucket/raw/"]
  bucket_arns   = ["arn:aws:s3:::bucket"]
}

run "creates_role_and_crawler" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-crawler-role"
    error_message = "Role name should be derived from crawler name"
  }

  assert {
    condition     = aws_glue_crawler.this.name == "test-crawler"
    error_message = "Crawler name should match input"
  }

  assert {
    condition     = aws_glue_crawler.this.database_name == "test_db"
    error_message = "Database should be propagated"
  }

  assert {
    condition     = length(aws_glue_crawler.this.s3_target) == 1
    error_message = "Should create one s3_target per input path"
  }
}

run "table_prefix_is_applied" {
  command = plan

  variables {
    table_prefix = "raw_"
  }

  assert {
    condition     = aws_glue_crawler.this.table_prefix == "raw_"
    error_message = "table_prefix should be propagated"
  }
}

run "multiple_s3_targets" {
  command = plan

  variables {
    s3_targets = ["s3://bucket/raw/", "s3://bucket/curated/"]
  }

  assert {
    condition     = length(aws_glue_crawler.this.s3_target) == 2
    error_message = "Should create one s3_target per input path"
  }
}
