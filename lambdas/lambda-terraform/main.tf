# This Terraform config creates:
# 1) An IAM role with basic Lambda execution permissions
# 2) A Lambda function built from local source code in the ./lambda folder
#
# New: We automatically zip the Lambda source before deploy using the
#      hashicorp/archive provider, so you don't have to run zip manually.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version = "~> 5.0"  # Optional: pin a major version you’ve tested
    }
    archive = {
      source = "hashicorp/archive"
      # version = "~> 2.0"  # Optional: pin a version
    }
  }
  # required_version = ">= 1.5.0"  # Optional: pin your Terraform CLI version
}

# Configure the AWS provider. Set your preferred region.
provider "aws" {
  region = "us-east-1"
}

# IAM role that Lambda will assume when it runs.
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# Attach AWS-managed basic execution policy (writes logs to CloudWatch).
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Automatically zip everything inside the local ./lambda directory.
# - Keep this folder minimal (your code and any needed deps). If you use node_modules,
#   they will be included in the zip. Consider a build step if you need to prune dev deps.
# - The output zip lands at ./lambda.zip (which is git-ignored).
# - The hash changes whenever the contents change, ensuring updates are deployed.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Define the Lambda function.
resource "aws_lambda_function" "hello_js" {
  function_name = "hello-js"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"       # For Node.js, file is index.(js|mjs) exporting handler
  runtime       = "nodejs22.x"

  # Use the automatically created archive as the deployment package
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NODE_OPTIONS = "--enable-source-maps"
    }
  }
}
