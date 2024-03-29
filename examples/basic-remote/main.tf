
# basic example of using this module remotely

terraform {
  backend "local" {
  }
}

module "worklytics_export" {
  source  = "terraform-aws-worklytics-export"
  version = "~> 0.4.0"

  resource_name_prefix = var.resource_name_prefix
  worklytics_tenant_id = var.worklytics_tenant_id
  worklytics_host      = var.worklytics_host
  todos_as_outputs     = var.todos_as_outputs
  todos_as_local_files = var.todos_as_local_files
}

output "worklytics_export_bucket_id" {
  value = module.worklytics_export.worklytics_export_bucket.id
}

output "worklytics_tenant_aws_role_arn" {
  value = module.worklytics_export.worklytics_tenant_aws_role.arn
}
