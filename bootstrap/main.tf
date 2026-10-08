data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" { bucket = var.state_bucket_name }
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

resource "aws_iam_role" "github" {
  name = "github-actions-terraform-hello-world"
  assume_role_policy = jsonencode({
    Version="2012-10-17", Statement=[{
      Effect="Allow", Principal={Federated=aws_iam_openid_connect_provider.github.arn},
      Action="sts:AssumeRoleWithWebIdentity",
      Condition={
        StringEquals={"token.actions.githubusercontent.com:aud"="sts.amazonaws.com"},
        StringLike={"token.actions.githubusercontent.com:sub"="repo:${var.github_owner}/${var.github_repository}:*"}
      }
    }]
  })
}

resource "aws_iam_role_policy" "github" {
  role = aws_iam_role.github.id
  policy = jsonencode({Version="2012-10-17",Statement=[
    {Effect="Allow",Action=["ec2:*","ssm:SendCommand","ssm:GetCommandInvocation","ssm:ListCommandInvocations"],Resource="*"},
    {Effect="Allow",Action=["iam:CreateRole","iam:DeleteRole","iam:GetRole","iam:TagRole","iam:UntagRole","iam:PutRolePolicy","iam:GetRolePolicy","iam:DeleteRolePolicy","iam:PassRole","iam:CreateInstanceProfile","iam:DeleteInstanceProfile","iam:GetInstanceProfile","iam:AddRoleToInstanceProfile","iam:RemoveRoleFromInstanceProfile"],Resource="*"},
    {Effect="Allow",Action=["s3:ListBucket","s3:GetBucketLocation"],Resource=[aws_s3_bucket.state.arn,"arn:aws:s3:::${var.github_owner}-hello-world-*" ]},
    {Effect="Allow",Action=["s3:GetObject","s3:PutObject","s3:DeleteObject"],Resource=["${aws_s3_bucket.state.arn}/*","arn:aws:s3:::${var.github_owner}-hello-world-*/*"]}
  ]})
}

output "github_role_arn" { value = aws_iam_role.github.arn }
output "state_bucket" { value = aws_s3_bucket.state.id }
