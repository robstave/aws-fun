# Lambda (Terraform) — Auto-zip and Deploy

This project deploys an AWS Lambda function using Terraform. The Lambda code lives in `./lambda` and is automatically zipped by the `hashicorp/archive` provider—no manual zip needed.

## Prerequisites (Windows)

- Terraform: `winget install -e --id HashiCorp.Terraform`
- AWS CLI v2: `winget install -e --id Amazon.AWSCLI`
- AWS credentials: `aws configure` (use region in `main.tf`, default is `us-east-1`)
- Optional: Node.js if you’re writing Node code for the Lambda

## Project layout

- `main.tf` — Terraform config (providers, IAM role, Lambda function)
- `lambda/` — Lambda source folder (everything inside is zipped and deployed)
- `lambda.zip` — Generated automatically; ignored by git

The Lambda runtime is `nodejs22.x` and the handler is `index.handler` (`index.js` exports `handler`).

## Quick start

1) Go to this project folder:

```powershell
cd "c:\Users\robst\OneDrive\Documents\githubs\aws-exercises\lambda-terraform"
```

2) Add Lambda code (if you don’t have any yet):

```javascript
// filepath: c:\Users\robst\OneDrive\Documents\githubs\aws-exercises\lambda-terraform\lambda\index.js
exports.handler = async (event) => {
  const name = event?.name ?? "world";
  return { statusCode: 200, body: JSON.stringify({ message: `Hello, ${name}!` }) };
};
```

3) Initialize providers:

```powershell
terraform init
```

4) Preview and apply:

```powershell
terraform plan
terraform apply
```

Terraform will:
- Create an IAM role with basic execution policy
- Zip `./lambda` into `lambda.zip`
- Upload and create/update the Lambda function `hello-js`

## Invoke with a JSON event

You can test with a JSON payload either in the AWS Console or via AWS CLI.

### AWS Console (Test event)

1) Open AWS Console → Lambda → Functions → `hello-js`
2) Click “Test” → “Create new event”
3) Event JSON (example):

```json
{
  "key1": "Hello",
  "key2": 5,
  "key3": 10
}
```

4) Save, then click “Test” to invoke and view the response.

### AWS CLI (PowerShell)

CLI v2 needs the binary format flag for raw JSON:

```powershell
aws lambda invoke `
  --function-name hello-js `
  --cli-binary-format raw-in-base64-out `
  --payload '{ "key1": "Hello", "key2": 5, "key3": 10 }' `
  out.json

Get-Content .\out.json
```

Alternatively build JSON safely in PowerShell:

```powershell
$payload = @{ key1 = "Hello"; key2 = 5; key3 = 10 } | ConvertTo-Json
aws lambda invoke --function-name hello-js --cli-binary-format raw-in-base64-out --payload $payload out.json
Get-Content .\out.json
```

## Update and redeploy

- Edit files under `./lambda`
- Re-run:

```powershell
terraform apply
```

The archive hash changes when code changes, so Terraform updates the function.

## Clean up

Destroy all resources created by this module:

```powershell
terraform destroy
```

## Notes

- `lambda.zip` is generated automatically and ignored by git.
- If the function isn’t found when invoking, verify AWS region matches `main.tf`.
- For Node projects with dependencies, consider a build step to include only production deps in `./lambda`.
