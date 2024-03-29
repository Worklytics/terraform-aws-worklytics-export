# Worklytics Export to AWS Terraform Module

[![Latest Release](https://img.shields.io/github/v/release/Worklytics/terraform-aws-worklytics-export)](https://github.com/Worklytics/terraform-aws-worklytics-export/releases/latest)
[![tests](https://img.shields.io/github/actions/workflow/status/Worklytics/terraform-aws-worklytics-export/terraform_integration.yaml?label=tests)](https://github.com/Worklytics/terraform-aws-worklytics-export/actions?query=branch%3Amain)

This module creates infra to support exporting data from Worklytics to AWS.

It is published in the [Terraform Registry](https://registry.terraform.io/modules/Worklytics/worklytics-export/aws/latest).

If it does not meet your needs, feel free to directly copy the `main.tf` file into your own Terraform
configuration and adapt it to your requirements.

## Usage

from Terraform registry:
```hcl
module "worklytics-export" {
  source  = "terraform-aws-worklytics-export"
  version = "~> 0.4.0"

  # numeric ID of your Worklytics Tenant SA
  worklytics_tenant_id = "123123123123"
}
```

via GitHub:
```hcl
module "worklytics-export" {
  source  = "git::https://github.com/worklytics/terraform-aws-worklytics-export/?ref=v0.4.0"

  # numeric ID of your Worklytics Tenant SA
  worklytics_tenant_id = "123123123123"
}
```

## Outputs

#### `worklytics_export_bucket`
The Terraform resource created as the export bucket. See [`aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) for details.

This is useful to compose with the other `aws_s3_bucket_*` resources to configure retention, encryption, etc. See:
  - [aws_s3_bucket_lifecycle_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)
  - [aws_s3_bucket_service_side_encryption_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration)

#### `worklytics_tenant_aws_role`
The IAM role that your Worklytics Tenant will assume before operating on your AWS infrastructure.

Eg, Worklytics's infra will do the equivalent of [`aws sts assume-role`](https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html)
on this role, authenticated by GCP as the GCP Service Account you identified with
`worklytics_tenant_id`.

See [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
for general idea; this is the reverse direction of that (GCP --> AWS, rather than AWS --> GCP).

This value is useful for a few scenarios:
  - if you set a CMEK to encrypt the bucket rather than relying on AWS default, you may need to
    grant encrypt / data key creation permissions to this role.
  - if your AWS account has additional IAM policies which would *deny* the permissions needed by
    this role for S3/etc, use this role's ARN to add exceptions to those policies
    (in AWS IAM logic, explicit deny has precedence over explicit allow)

## Compatibility

This module is meant for use with Terraform 1.1+. If you find incompatibilities using Terraform >=
1.1, please open an issue.

## Usage Tips

### Existing Bucket

If you wish to export Worklytics data to an existing bucket, use a Terraform import as follows:

```bash
terraform import module.worklytics_export.aws_s3_bucket.worklytics_export <bucket_name>
```

### Customize Public Access Block
By default, we set a restrictive public access block on the bucket.  If you need something more
permissive, you can disable the default block by setting the variable `enable_aws_s3_bucket_public_access_block=false`
in your `terraform.tfvars` file and then add your own public access block as follows:

```tf
resource "aws_s3_bucket_public_access_block" "worklytics_export" {
  bucket = module.worklytics_export.worklytics_export_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Add a Max Retention Policy

It's good practice to have a max retention policy on your bucket, even if it's really long. If you
have a data pipeline regularly moving data from this bucket into your data warehouse, a value of 30
or 60 days can likely lower your storage costs and reduce risk of having data in more places than it
needs to be.

```tf
resource "aws_s3_bucket_lifecycle_configuration" "worklytics_export" {
  bucket = module.worklytics_export.worklytics_export_bucket.id

  rule {
    id      = "max_retention_5_years"
    enabled = true

    expiration {
      days = 5*365 # 5 years
    }
  }
}

```

## Development

This module is written and maintained by [Worklytics, Co.](https://worklytics.co/) and intended to
guide our customers in setting up their own infra to export data from Worklytics to AWS.

As this is [published as a Terraform module](https://developer.hashicorp.com/terraform/registry/modules/publish),
we will strive to follow [standard Terraform module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
and [style conventions](https://developer.hashicorp.com/terraform/language/syntax/style).

See [examples/basic/](examples/basic/) for a simple example of how to use this module.

(c) 2023 Worklytics, Co
