
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
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

resource "aws_iam_policy" "allow_worklytics_tenant_bucket_access" {
  count = var.worklytics_tenant_id == null ? 0 : 1

  policy = jsonencode({
    statement = [
      {
        sid    = "AllowWorklyticsTenantBucketAccess"
        effect = "Allow"
        principal = {
          federated = "accounts.google.com"
          condition = {
            "StringEquals" = {
              "accounts.google.com:aud" : var.worklytics_tenant_id
            }
          }
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


