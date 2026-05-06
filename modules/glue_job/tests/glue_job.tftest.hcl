mock_provider "aws" {}

variables {
  name              = "test-job"
  script_local_path = "tests/fixtures/script.py"
  scripts_bucket    = "scripts-bucket"
  data_bucket_arns  = ["arn:aws:s3:::data-bucket"]
}

run "creates_role_and_job" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-job-role"
    error_message = "Role name should be derived from job name"
  }

  assert {
    condition     = aws_glue_job.this.name == "test-job"
    error_message = "Job name should match input"
  }

  assert {
    condition     = aws_glue_job.this.glue_version == "4.0"
    error_message = "Default glue_version should be 4.0"
  }

  assert {
    condition     = aws_glue_job.this.worker_type == "G.1X"
    error_message = "Default worker_type should be G.1X"
  }

  assert {
    condition     = aws_s3_object.script.bucket == "scripts-bucket"
    error_message = "Script should be uploaded to scripts_bucket"
  }
}

run "default_arguments_are_merged" {
  command = plan

  variables {
    default_arguments = {
      "--raw_path" = "s3://bucket/raw/"
    }
  }

  assert {
    condition     = aws_glue_job.this.default_arguments["--raw_path"] == "s3://bucket/raw/"
    error_message = "User-provided default_arguments should be present"
  }

  assert {
    condition     = aws_glue_job.this.default_arguments["--enable-metrics"] == "true"
    error_message = "Built-in default arguments should remain"
  }
}

run "command_uses_glueetl" {
  command = plan

  assert {
    condition     = one(aws_glue_job.this.command[*].name) == "glueetl"
    error_message = "Command name should be glueetl"
  }

  assert {
    condition     = one(aws_glue_job.this.command[*].python_version) == "3"
    error_message = "Python version should be 3"
  }
}
