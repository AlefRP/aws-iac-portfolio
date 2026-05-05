locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

module "s3_bucket" {
  source = "./modules/s3_bucket"

  bucket_name        = var.bucket_name
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

resource "aws_s3_object" "sample" {
  bucket = module.s3_bucket.bucket_id
  key    = "texto.txt"
  source = "${path.module}/texto.txt"
  etag   = filemd5("${path.module}/texto.txt")
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "AllowBucketOperations"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      module.s3_bucket.bucket_arn,
      "${module.s3_bucket.bucket_arn}/*",
    ]
  }
}

module "iam_user" {
  source = "./modules/iam_user"

  user_name = var.iam_user_name

  inline_policies = {
    "s3-bucket-access" = data.aws_iam_policy_document.s3_access.json
  }

  tags = local.common_tags
}
