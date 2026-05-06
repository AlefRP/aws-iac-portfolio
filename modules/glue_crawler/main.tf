resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3" {
  name = "${var.name}-s3"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = var.bucket_arns
      },
      {
        Sid      = "ReadObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = [for arn in var.bucket_arns : "${arn}/*"]
      },
    ]
  })
}

resource "aws_glue_crawler" "this" {
  name          = var.name
  role          = aws_iam_role.this.arn
  database_name = var.database_name
  table_prefix  = var.table_prefix
  schedule      = var.schedule
  configuration = var.configuration

  dynamic "s3_target" {
    for_each = var.s3_targets
    content {
      path = s3_target.value
    }
  }

  tags = var.tags
}
