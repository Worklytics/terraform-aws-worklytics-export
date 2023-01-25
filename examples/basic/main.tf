
# basic example of using this module; really as much for dev/testing as a real example of practical
# usage

module "worklytics_export" {
  source = "../../"

  worklytics_tenant_id = var.worklytics_tenant_id
}
