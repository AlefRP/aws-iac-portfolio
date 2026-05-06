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

resource "aws_iam_role_policy" "data_access" {
  name = "${var.name}-data-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = var.data_bucket_arns
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [for arn in var.data_bucket_arns : "${arn}/*"]
      },
    ]
  })
}

resource "aws_s3_object" "script" {
  bucket = var.scripts_bucket
  key    = "${var.scripts_prefix}/${var.name}.py"
  source = var.script_local_path
  etag   = filemd5(var.script_local_path)
}

resource "aws_glue_job" "this" {
  name              = var.name
  role_arn          = aws_iam_role.this.arn
  glue_version      = var.glue_version
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  timeout           = var.timeout_minutes
  max_retries       = var.max_retries

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket}/${aws_s3_object.script.key}"
    python_version  = "3"
  }

  default_arguments = merge(
    {
      "--job-language"                     = "python"
      "--enable-metrics"                   = "true"
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-job-insights"              = "true"
    },
    var.default_arguments,
  )

  tags = var.tags
}
