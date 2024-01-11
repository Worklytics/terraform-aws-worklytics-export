
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

# you can use `aws_s3_bucket_public_access_block` to disable this, as these defaults are extreme.
# if you do, we recommend setting something similar outside this module
resource "aws_s3_bucket_public_access_block" "worklytics_export" {
  count = var.enable_aws_s3_bucket_public_access_block ? 1 : 0

  bucket = aws_s3_bucket.worklytics_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
# Configure Data Export in Worklytics

1. Ensure you're authenticated with Worklytics. Either sign-in at [https://${var.worklytics_host}](https://${var.worklytics_host})
  with your organization's SSO provider *or* request OTP link from your Worklytics support.
2. Visit `https://${var.worklytics_host}/analytics/data-export/connect?type=AMAZON_S3&bucket=${aws_s3_bucket
.worklytics_export.bucket}&roleArn=${aws_iam_role.for_worklytics_tenant.arn}`
3. Review any additional settings (such as the Dataset type you'd like to export) and adjust
  values as you see fit, then click "Create Data Export".

Alternatively, you may follow the manual instructions below:

1. Visit [https://${var.worklytics_host}/analytics/data-export](https://${var.worklytics_host}/analytics/data-export)
  (or login into Worklytics, and navigate to Manage --> Export Data).
2. Click on the 'Create New Data Export' button in the upper right.
3. Fill in the form with the following values:
  - **Data Export Name** - choose a name that will help you identify this export in the future.
  - **Data Export Type** - choose the type of data you'd like to export. Check our
    [Data Export Documentation](https://${var.worklytics_host}/docs/data-export) for a complete
    description of all the available datasets.
  - **Data Destination** - choose 'Amazon S3', use `${aws_s3_bucket.worklytics_export.bucket}`
    for the **Bucket** field, and `${aws_iam_role.for_worklytics_tenant.arn}` for the **Role ARN**
    field.

EOT
}

resource "local_file" "todo" {
  count = var.todos_as_local_files ? 1 : 0

  filename = "TODO - configure export in worklytics.md"

  content = local.todo_content
}

# moved in 0.4.0
moved {
  from = local_file.todo
  to   = local_file.todo[0]
}
