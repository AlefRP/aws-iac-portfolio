mock_provider "aws" {}

variables {
  name = "test_db"
}

run "creates_database_with_name" {
  command = plan

  assert {
    condition     = aws_glue_catalog_database.this.name == "test_db"
    error_message = "Database name should match input"
  }
}

run "description_is_propagated" {
  command = plan

  variables {
    description = "Test catalog database"
  }

  assert {
    condition     = aws_glue_catalog_database.this.description == "Test catalog database"
    error_message = "Description should be propagated"
  }
}
