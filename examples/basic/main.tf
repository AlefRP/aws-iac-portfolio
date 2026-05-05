module "bucket" {
  source = "../../modules/s3_bucket"

  bucket_name        = "example-basic-bucket-2026"
  versioning_enabled = true

  tags = {
    Environment = "example"
    Project     = "terraform-aws-demo"
  }
}

data "aws_iam_policy_document" "read_only" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [module.bucket.bucket_arn, "${module.bucket.bucket_arn}/*"]
  }
}

module "reader" {
  source = "../../modules/iam_user"

  user_name = "example-reader"
  inline_policies = {
    "read-bucket" = data.aws_iam_policy_document.read_only.json
  }
}

output "bucket_id" {
  value = module.bucket.bucket_id
}

output "reader_arn" {
  value = module.reader.user_arn
}
