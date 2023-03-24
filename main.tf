
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "for_worklytics_tenant" {

  name = "${var.resource_name_prefix}Tenant"

  # if `worklytics_tenant_id` is null, then use a placeholder `assume_role_policy` that allows,
  # to support pre-production use case (where infra is created for review, but inaccessible)
  assume_role_policy = var.worklytics_tenant_id == null ? jsonencode({
    Version = "2012-10-17"
    Statement = {
      Sid    = "AllowOwnAccountToAssumeRole"
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        "AWS" = data.aws_caller_identity.current.account_id
      }
    }
    }) : jsonencode({
    Version = "2012-10-17"
    Statement = {
      Sid    = "AllowWorklyticsTenantToAssumeRole"
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "accounts.google.com"
      }
      Condition = {
        StringEquals = {
          "accounts.google.com:aud" = var.worklytics_tenant_id
        }
      }
    }
  })
}


resource "aws_s3_bucket" "worklytics_export" {
  bucket_prefix = replace(lower(var.resource_name_prefix), "_", "-")

  lifecycle {
    ignore_changes = [
      # don't conflict with tags customers might wish to add themselves
      tags,
    ]
  }
}

resource "aws_s3_bucket_acl" "worklytics_export_private" {
  bucket = aws_s3_bucket.worklytics_export.id
  acl    = "private"
}

# TODO if key, need perm to "kms:GenerateDataKey" and "kms:Decrypt" ??
# q - do we leave that to customer, or support it natively since pretty common case??

resource "aws_iam_policy" "allow_worklytics_tenant_bucket_access" {
  name = "${var.resource_name_prefix}TenantBucketAccess"

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "WorklyticsTenantAccessExportBucket",
    Statement = [
      {
        Sid    = "AllowWorklyticsTenantBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",

          # to support rsync, has to be able to list and get objects
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListObjectsV2",
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.worklytics_export.id}",
          "arn:aws:s3:::${aws_s3_bucket.worklytics_export.id}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "allow_worklytics_tenant_bucket_access" {
  name       = "allow_worklytics_tenant_bucket_access"
  policy_arn = aws_iam_policy.allow_worklytics_tenant_bucket_access.arn
  roles = [
    aws_iam_role.for_worklytics_tenant.name
  ]
}

locals {
  todo_content = <<EOT
# Configure Export in Worklytics

  1. Go to [https://app.worklytics.co/](https://app.worklytics.co/), navigate to 'Export Data' and
     'Create new connection'.
  2. Set `Location` to `s3://${aws_s3_bucket.worklytics_export.bucket}`
  3. Set `Role` to `${aws_iam_role.for_worklytics_tenant.arn}`

EOT
}

resource "local_file" "todo" {
  filename = "TODO - configure export in worklytics.md"

  content = local.todo_content
}

