# Lambda with API Gateway (Terraform)

This project deploys an AWS Lambda function exposed through an API Gateway HTTP API. The setup includes:

- Lambda function with automatic zipping
- API Gateway HTTP API (v2)
- Routes for both root path `/` and parameterized path `/{value}`
- CORS configuration
- CloudWatch logging

## Prerequisites (Windows)

- Terraform: `winget install -e --id HashiCorp.Terraform`
- AWS CLI v2: `winget install -e --id Amazon.AWSCLI`
- AWS credentials: `aws configure` (use region in `main.tf`, default is `us-east-1`)
- Optional: Node.js if you want to test locally

## Project layout

- `main.tf` — Terraform config with API Gateway and Lambda
- `lambda/` — Lambda source folder (automatically zipped)
- `lambda.zip` — Generated automatically, ignored by git

## Lambda code

The Lambda function (`index.mjs`) extracts a path parameter `{value}` from the URL and returns it as JSON.

Example URL: `https://your-api-id.execute-api.region.amazonaws.com/hello`
Response: Contains the path parameter value, query parameters, and request details.

## Quick start

1) Go to this project folder:

```powershell
cd "c:\Users\robst\OneDrive\Documents\githubs\aws-exercises\lambdas\lambda-api-terraform"
```

2) Initialize providers:

```powershell
terraform init
```

3) Preview and apply:

```powershell
terraform plan
terraform apply
```

4) After deployment, Terraform will output the API URL. Use it to call your endpoints:

- Root endpoint: `https://<api-id>.execute-api.<region>.amazonaws.com/`
- With path parameter: `https://<api-id>.execute-api.<region>.amazonaws.com/hello`
- With query parameters: `https://<api-id>.execute-api.<region>.amazonaws.com/hello?name=world&foo=bar`

## Testing the API

### Browser

Simply open the URL in your browser:
```
https://<api-id>.execute-api.<region>.amazonaws.com/hello
```

### PowerShell

```powershell
Invoke-RestMethod -Uri "https://<api-id>.execute-api.<region>.amazonaws.com/hello"
```

With query parameters:
```powershell
Invoke-RestMethod -Uri "https://<api-id>.execute-api.<region>.amazonaws.com/hello?name=world"
```

### curl

```powershell
curl "https://<api-id>.execute-api.<region>.amazonaws.com/hello"
```

## Update and redeploy

- Edit files under `./lambda`
- Re-run:

```powershell
terraform apply
```

## View logs

You can view the Lambda function logs and API Gateway logs in CloudWatch:

1. Go to AWS CloudWatch console
2. Check `/aws/lambda/api-lambda` for Lambda logs
3. Check `/aws/apigateway/lambda-http-api` for API Gateway logs

## Clean up

Destroy all resources created by this module:

```powershell
terraform destroy
```

## Notes

- API Gateway HTTP API (v2) is used instead of the older REST API (v1) as it's more cost-effective and streamlined
- CORS is enabled for all origins (customize in `main.tf` if needed)
- The API returns proper JSON with appropriate headers
- Path parameters are extracted from `event.pathParameters` in the Lambda
- Query parameters are accessible via `event.queryStringParameters`
