# Terraform AWS Hello World

Minimal-cost demonstration of Terraform, GitHub Actions, immutable infrastructure principles, ZIP artifact promotion, SSM deployment, health checks, rollback, and teardown.

## One-time setup

1. Create a personal GitHub repository and push this project.
2. On your personal machine, authenticate to the AWS sandbox with an administrator/bootstrap identity.
3. Copy `bootstrap/terraform.tfvars.example` to `bootstrap/terraform.tfvars`, supply unique names, then run:

```bash
cd bootstrap
terraform init
terraform apply
```

If an OIDC provider for GitHub already exists in the AWS account, import it or remove the OIDC provider resource and reference the existing provider.

4. In GitHub create environment `dev`. Add these environment variables:
   - `AWS_ROLE_ARN`: bootstrap output `github_role_arn`
   - `TF_STATE_BUCKET`: bootstrap output `state_bucket`
   - `ARTIFACT_BUCKET_NAME`: globally unique, lowercase S3 bucket name
5. Push to `main` or run **Build, provision and deploy** manually.
6. Use the URL printed by the deployment job.
7. Run **Destroy infrastructure**, entering `DESTROY`, when finished.

## Important

- Confirm `t3.micro` is Free Tier eligible for your account and region before deploying.
- The site is intentionally HTTP-only for this learning project. Do not expose sensitive data.
- GitHub stores the canonical ZIP artifact. S3 is temporary transport because the EC2 instance cannot directly download a private GitHub Actions artifact.
- The example bootstrap policy is scoped for a learning account but still broad for EC2. Do not reuse it for production.
- The instance has no inbound SSH rule. Administration and deployment use AWS Systems Manager.
