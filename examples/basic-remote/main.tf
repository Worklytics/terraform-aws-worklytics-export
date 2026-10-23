
# basic example of using this module remotely

terraform {
  backend "local" {
  }

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

module "worklytics_export" {
  source  = "Worklytics/worklytics-export/aws"
  version = "~> 2.0.0"

  resource_name_prefix = var.resource_name_prefix
  worklytics_tenant_id = var.worklytics_tenant_id
  worklytics_host      = var.worklytics_host
}

resource "local_file" "todo" {
  filename = "TODO - configure export in worklytics.md"
  content  = module.worklytics_export.todo_markdown
}

output "worklytics_export_bucket_id" {
  value = module.worklytics_export.worklytics_export_bucket.id
}

output "worklytics_tenant_aws_role_arn" {
  value = module.worklytics_export.worklytics_tenant_aws_role.arn
}
