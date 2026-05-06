mock_provider "aws" {}
mock_provider "archive" {}

variables {
  function_name = "test-fn"
  source_dir    = "tests/fixtures"
}

run "minimal_creates_role_and_function" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-fn-role"
    error_message = "Role name should be derived from function_name"
  }

  assert {
    condition     = aws_lambda_function.this.function_name == "test-fn"
    error_message = "Lambda name should match input"
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.12"
    error_message = "Default runtime should be python3.12"
  }

  assert {
    condition     = aws_lambda_function.this.handler == "handler.lambda_handler"
    error_message = "Default handler should be handler.lambda_handler"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 0
    error_message = "No schedule should be created when schedule_expression is null"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 14
    error_message = "Default log retention should be 14 days"
  }
}

run "schedule_creates_eventbridge_rule" {
  command = plan

  variables {
    schedule_expression = "cron(0 6 * * ? *)"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 1
    error_message = "EventBridge rule should be created when schedule is set"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.schedule[0].schedule_expression == "cron(0 6 * * ? *)"
    error_message = "Schedule expression should match input"
  }

  assert {
    condition     = length(aws_lambda_permission.schedule) == 1
    error_message = "Lambda permission should be created when schedule is set"
  }
}

run "extra_policy_is_attached_when_provided" {
  command = plan

  variables {
    additional_policy_statements = [
      {
        sid       = "WriteS3"
        effect    = "Allow"
        actions   = ["s3:PutObject"]
        resources = ["arn:aws:s3:::bucket/*"]
      }
    ]
  }

  assert {
    condition     = length(aws_iam_role_policy.extra) == 1
    error_message = "Extra inline policy should be created"
  }
}

run "environment_variables_are_set" {
  command = plan

  variables {
    environment_variables = {
      DATA_BUCKET = "my-bucket"
      TICKERS     = "AAPL,MSFT"
    }
  }

  assert {
    condition     = one(aws_lambda_function.this.environment[*].variables["DATA_BUCKET"]) == "my-bucket"
    error_message = "Environment variable DATA_BUCKET should be propagated"
  }
}
