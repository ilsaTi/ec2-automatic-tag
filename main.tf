terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

data "local_file" "lambda_policy" {
  filename = "policy/lambda_policy.json"
}
data "local_file" "lambda_assumeRole_policy" {
  filename = "policy/lambda_assumeRole_policy.json"
}

data "local_file" "event_pattern" {
  filename = "event/event_pattern.json"
}


resource "aws_lambda_function" "function" {
  filename      = "code/code.zip"
  function_name = "tagEc2"
  role          = aws_iam_role.lambda_assumeRole_policy.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
        TAG_KEY = var.tag_key
    }
  }
  timeout = 600
}

# role lambda
resource "aws_iam_role" "lambda_assumeRole_policy" {
  name = "tagEc2-Role"
  assume_role_policy = data.local_file.lambda_assumeRole_policy.content
}

# iam policy
resource "aws_iam_role_policy" "pol" {
  name = "lambda_tagEc2_policy"
  role = aws_iam_role.lambda_assumeRole_policy.id
  policy = data.local_file.lambda_policy.content
}

# ----- ----- 
resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "launch-auto-tags"
  description = ""
  event_pattern = data.local_file.event_pattern.content
}

resource "aws_cloudwatch_event_target" "target" {
  target_id = "lambda"
  rule      = aws_cloudwatch_event_rule.event_rule.name
  arn       = aws_lambda_function.function.arn
}