
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

resource "aws_iam_role" "worklytics_tenant" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "accounts.google.com"
        }
        Condition = {
          StringEquals = {
            "accounts.google.com:aud" : var.worklytics_tenant_id
          }
        }
      }
    ]
  })
}


resource "aws_s3_bucket" "worklytics_export" {
  bucket_prefix = var.bucket_name_prefix

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
  count = var.worklytics_tenant_id == null ? 0 : 1

  policy = jsonencode({
    statement = [
      {
        sid    = "AllowWorklyticsTenantBucketAccess"
        effect = "Allow"
        principal = {
          AWS = aws_iam_role.worklytics_tenant.arn
        }
        actions = [
          "s3:PutObject",

          # to support rsync, has to be able to list and get objects
          "s3:GetObject",
          "s3:ListBucket",
        ]
        resources = [
          "arn:aws:s3:::${aws_s3_bucket.worklytics_export.id}",
          "arn:aws:s3:::${aws_s3_bucket.worklytics_export.id}/*",
        ]
      },
    ]
  })
}


