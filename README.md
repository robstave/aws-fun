# aws-exercises

## Terraform setup

- Install Terraform:
  - Windows: Download terraform.exe from HashiCorp and place it in a folder on your PATH (e.g., %USERPROFILE%\bin). Verify with `terraform -version`.
  - macOS/Linux: Use your package manager or download from HashiCorp, then verify with `terraform -version`.
- Initialize a project: run `terraform init` inside each project directory containing `.tf` files.
- Common workflow per project directory:
  - `terraform fmt` — format Terraform files
  - `terraform validate` — validate configuration
  - `terraform plan` — preview changes
  - `terraform apply` — apply changes
  - `terraform destroy` — tear down resources when appropriate

Notes
- This repo contains multiple Terraform projects in subfolders. Run Terraform commands from within each project's directory.
- The repo-wide `.gitignore` excludes `terraform.exe` anywhere in the tree to avoid committing the binary.
- Consider using a remote backend for state when collaborating (e.g., S3 + DynamoDB locking).
- Keep secrets out of VCS. Use variables and a local `*.tfvars` ignored by git, or a secrets manager.
