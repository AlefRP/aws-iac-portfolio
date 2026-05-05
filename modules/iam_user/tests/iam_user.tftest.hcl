mock_provider "aws" {}

variables {
  user_name = "test-deploy-user"
  tags = {
    Environment = "test"
  }
}

run "minimal_user_creation" {
  command = plan

  assert {
    condition     = aws_iam_user.this.name == "test-deploy-user"
    error_message = "User name must match input"
  }

  assert {
    condition     = aws_iam_user.this.path == "/"
    error_message = "Default path should be /"
  }

  assert {
    condition     = aws_iam_user.this.force_destroy == false
    error_message = "force_destroy should default to false"
  }

  assert {
    condition     = length(aws_iam_access_key.this) == 0
    error_message = "Access key should not be created by default"
  }
}

run "tags_include_name" {
  command = plan

  assert {
    condition     = aws_iam_user.this.tags["Name"] == "test-deploy-user"
    error_message = "Name tag must be set to user_name"
  }

  assert {
    condition     = aws_iam_user.this.tags["Environment"] == "test"
    error_message = "Tags from input must be propagated"
  }
}

run "inline_policies_are_created" {
  command = plan

  variables {
    inline_policies = {
      "policy-a" = jsonencode({ Version = "2012-10-17", Statement = [] })
      "policy-b" = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  assert {
    condition     = length(aws_iam_user_policy.inline) == 2
    error_message = "Should create one inline policy per map entry"
  }
}

run "managed_policies_are_attached" {
  command = plan

  variables {
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess",
    ]
  }

  assert {
    condition     = length(aws_iam_user_policy_attachment.managed) == 1
    error_message = "Managed policy attachments should match input list length"
  }
}

run "access_key_created_when_requested" {
  command = plan

  variables {
    create_access_key = true
  }

  assert {
    condition     = length(aws_iam_access_key.this) == 1
    error_message = "Access key should be created when create_access_key is true"
  }
}

run "rejects_empty_user_name" {
  command = plan

  variables {
    user_name = ""
  }

  expect_failures = [
    var.user_name,
  ]
}
