mock_provider "aws" {}

variables {
  bucket_name = "valid-bucket-name-2026"
  tags = {
    Environment = "test"
    Project     = "tf-tests"
  }
}

run "defaults_apply_security_baseline" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls must be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy must be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls must be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets must be true by default"
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration[*].status) == "Enabled"
    error_message = "Versioning must be enabled by default"
  }

  assert {
    condition     = one([for r in aws_s3_bucket_server_side_encryption_configuration.this.rule : one(r.apply_server_side_encryption_by_default[*].sse_algorithm)]) == "AES256"
    error_message = "SSE-S3 (AES256) must be the default encryption"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false to prevent accidental data loss"
  }
}

run "tags_are_merged_with_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.tags["Name"] == var.bucket_name
    error_message = "Name tag must be set to bucket_name"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "test"
    error_message = "User tags must be propagated"
  }
}

run "kms_encryption_when_arn_provided" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd-efgh"
  }

  assert {
    condition     = one([for r in aws_s3_bucket_server_side_encryption_configuration.this.rule : one(r.apply_server_side_encryption_by_default[*].sse_algorithm)]) == "aws:kms"
    error_message = "Should use SSE-KMS when kms_key_arn is provided"
  }
}

run "versioning_can_be_disabled" {
  command = plan

  variables {
    versioning_enabled = false
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration[*].status) == "Disabled"
    error_message = "Versioning should be Disabled when versioning_enabled is false"
  }
}

run "lifecycle_rules_create_configuration" {
  command = plan

  variables {
    lifecycle_rules = [
      {
        id                                 = "expire-old"
        noncurrent_version_expiration_days = 30
        abort_incomplete_multipart_days    = 7
      }
    ]
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 1
    error_message = "Lifecycle configuration should be created when rules are provided"
  }
}

run "rejects_short_bucket_name" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [
    var.bucket_name,
  ]
}

run "rejects_invalid_bucket_name_chars" {
  command = plan

  variables {
    bucket_name = "Invalid_Bucket"
  }

  expect_failures = [
    var.bucket_name,
  ]
}
