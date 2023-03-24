
# basic example of using this module; really as much for dev/testing as a real example of practical
# usage

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# provider just for example purposes; in real use, you likely already have an AWS provider block
# in your terraform configuration
provider "aws" {

  assume_role {
    role_arn = var.aws_role_name == null ? null : "arn:aws:iam::${var.aws_account_id}:role/${var.aws_role_name}"
  }

  allowed_account_ids = [
    var.aws_account_id
  ]
}



module "worklytics_export" {
  source = "../../"

  resource_name_prefix = var.resource_name_prefix
  worklytics_tenant_id = var.worklytics_tenant_id
}

output "worklytics_export_bucket_id" {
  value = module.worklytics_export.worklytics_export_bucket.id
}

output "worklytics_tenant_aws_role_arn" {
  value = module.worklytics_export.worklytics_tenant_aws_role.arn
}


