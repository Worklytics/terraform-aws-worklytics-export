
# basic example of using this module; really as much for dev/testing as a real example of practical
# usage

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}


module "worklytics_export" {
  source = "../../"

  resource_name_prefix = var.resource_name_prefix
  worklytics_tenant_id = var.worklytics_tenant_id
}

output "worklytics_export_bucket" {
  value = module.worklytics_export.worklytics_export_bucket
}

output "worklytics_tenant_aws_role" {
  value = module.worklytics_export.worklytics_tenant_aws_role
}
