# This Terraform config creates:
# 1) An IAM role with basic Lambda execution permissions
# 2) A Lambda function built from local source code in the ./lambda folder
# 3) An API Gateway to expose the Lambda through HTTP
#
# The API Gateway exposes a GET endpoint with a path parameter: GET /{value}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Automatically zip everything inside the local ./lambda directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# IAM role that Lambda will assume when it runs
resource "aws_iam_role" "lambda_exec_role" {
  name = "api_lambda_exec_role"

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

# Attach basic Lambda execution policy (for CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Define the Lambda function
resource "aws_lambda_function" "api_lambda" {
  function_name = "api-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
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

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any API Gateway stage and method
  # The source_arn format is: arn:aws:execute-api:{region}:{account-id}:{api-id}/{stage}/{method}/{resource}
  # The wildcard "*" allows any stage, method, and resource path
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# Create a new HTTP API (API Gateway v2)
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "lambda-http-api"
  protocol_type = "HTTP"
  description   = "HTTP API for Lambda function"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

# Create a stage for the API
resource "aws_apigatewayv2_stage" "lambda_api_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true

  # Configure logging for API Gateway
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }
}

# Create a log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.lambda_api.name}"
  retention_in_days = 7
}

# Define the main route with path parameter
resource "aws_apigatewayv2_route" "lambda_route_with_param" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /{value}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Define a default route for the root path
resource "aws_apigatewayv2_route" "lambda_route_root" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create the Lambda integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.lambda_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_lambda.invoke_arn
  integration_method     = "POST"  # Always POST for Lambda proxy integration
  payload_format_version = "2.0"   # Use the newer format that simplifies request/response handling
}

# Output the API Gateway URL
output "api_url" {
  value = aws_apigatewayv2_stage.lambda_api_stage.invoke_url
}

# Output specific example URLs
output "example_urls" {
  value = [
    "${aws_apigatewayv2_stage.lambda_api_stage.invoke_url}/test",
    "${aws_apigatewayv2_stage.lambda_api_stage.invoke_url}/hello?name=world"
  ]
}
