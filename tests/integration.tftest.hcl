mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.s3_access
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowBucketOperations\",\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\",\"s3:DeleteObject\",\"s3:ListBucket\",\"s3:GetBucketLocation\"],\"Resource\":[\"arn:aws:s3:::mock\",\"arn:aws:s3:::mock/*\"]}]}"
    }
  }
}

variables {
  bucket_name   = "integration-test-bucket-2026"
  iam_user_name = "integration-test-user"
  environment   = "dev"
  aws_region    = "us-east-1"
  aws_profile   = "default"
}

run "root_module_applies_successfully" {
  command = apply

  assert {
    condition     = module.iam_user.user_name == "integration-test-user"
    error_message = "Root module must produce the configured iam user"
  }

  assert {
    condition     = module.s3_bucket.bucket_id != ""
    error_message = "Root module must produce a non-empty bucket id"
  }

  assert {
    condition     = module.s3_bucket.bucket_arn != ""
    error_message = "Root module must produce a non-empty bucket ARN"
  }
}

run "iam_policy_is_scoped_to_bucket" {
  command = apply

  assert {
    condition     = length(data.aws_iam_policy_document.s3_access.statement) == 1
    error_message = "Policy document should contain exactly one statement"
  }

  assert {
    condition     = contains(data.aws_iam_policy_document.s3_access.statement[0].actions, "s3:GetObject")
    error_message = "Policy must allow s3:GetObject"
  }

  assert {
    condition     = !contains(data.aws_iam_policy_document.s3_access.statement[0].actions, "s3:*")
    error_message = "Policy must not grant wildcard s3:* (least privilege)"
  }
}

run "common_tags_propagate_to_modules" {
  command = apply

  variables {
    tags = {
      Project   = "tf-aws"
      ManagedBy = "terraform"
    }
  }

  assert {
    condition     = local.common_tags["Environment"] == "dev"
    error_message = "common_tags must include Environment from var.environment"
  }

  assert {
    condition     = local.common_tags["Project"] == "tf-aws"
    error_message = "common_tags must propagate user tags"
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
