terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}   

provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "archive" { }

data "archive_file" "zip" {
    type = "zip"
    source_file = "lambda_function.py"
    output_path = "lambda_function.zip"
}

data "aws_iam_policy_document" "policy" {
    statement {
      sid = ""
      effect = "Allow"

      principals {
        identifiers = ["lambda.amazonaws.com"]
        type = "Service"
      }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_lambda_function" "lambda" {
    function_name = "lambda_function"

    filename = data.archive_file.zip.output_path
    source_code_hash = data.archive_file.zip.output_base64sha256

    role = aws_iam_role.iam_for_lambda.arn
    handler = "lambda_function.lambda_handler"
    runtime = "python3.9"
}

resource "aws_dynamodb_table" "circuit-breaker-info-table" {
  name           = "circuit-breaker-info"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "contractId"

  attribute {
    name = "contractId"
    type = "S"
  }

  attribute {
    name = "circuitStatus"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

}