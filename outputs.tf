
# use bucket to compose with other modules:
#  - set ACL
#  - encrypt the output bucket, etc
output "worklytics_export_bucket" {
  value = aws_s3_bucket.worklytics_export
}

output "worklytics_tenant_aws_role" {
  value = aws_iam_role.for_worklytics_tenant
}
