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

4. In GitHub, under Settings > Secrets and variables > Actions, add these once at **repository** level so dev, staging and prod all use them:
   - Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - Variables:
     - `TF_STATE_BUCKET`: bootstrap output `state_bucket`
     - `ARTIFACT_BUCKET_NAME`: globally unique, lowercase S3 bucket name. Staging and prod automatically use it with `-staging` / `-prod` appended.
     - `APP_MESSAGE`: text shown on the page
   
   Then create the environments `dev`, `staging` and `prod` (they are also created automatically on first run). Optionally enable **Required reviewers** on `prod` for a manual approval gate. Remove any duplicate secrets or variables from the `dev` environment itself.
5. Push to `main` or run **Build and promote** manually. The pipeline runs lint, then builds once, then deploys the same artifact to `dev`, `staging` and `prod` in order. Each stage runs a smoke test; a failure rolls that environment back and stops promotion.
6. To test rollback, run **Build and promote** manually and set `simulate_failure_in` to an environment. That environment's smoke test is forced to fail, so it rolls back to the previous release and later stages do not run. Deploy successfully at least once first, so there is a release to roll back to.
7. Use the URLs printed by each deployment job. Instances are named `Emmanuel-Multiverse-Project5-<env>`.
8. Run **Destroy infrastructure**, choosing an environment and entering `DESTROY`, when finished.

## Important

- Confirm `t3.micro` is Free Tier eligible for your account and region before deploying.
- The site is intentionally HTTP-only for this learning project. Do not expose sensitive data.
- GitHub stores the canonical ZIP artifact. S3 is temporary transport because the EC2 instance cannot directly download a private GitHub Actions artifact.
- The example bootstrap policy is scoped for a learning account but still broad for EC2. Do not reuse it for production.
- The instance has no inbound SSH rule. Administration and deployment use AWS Systems Manager.
