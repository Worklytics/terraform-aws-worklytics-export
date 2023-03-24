
# use bucket to compose with other modules:
#  - set ACL
#  - encrypt the output bucket, etc
output "worklytics_export_bucket" {
  value       = aws_s3_bucket.worklytics_export
  description = "The Terraform resource created as the export bucket. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#attributes-reference  for details."
}

output "worklytics_tenant_aws_role" {
  value       = aws_iam_role.for_worklytics_tenant
  description = "The IAM role that your Worklytics Tenant will assume before operating on your AWS infrastructure. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#attributes-reference for details. Useful for composing with additional Terraform code, to support advanced deployment scenarios."
}

output "todo_markdown" {
  value       = local.todo_content
  description = "Actions that must be performed outside of Terraform (markdown format)."
}
