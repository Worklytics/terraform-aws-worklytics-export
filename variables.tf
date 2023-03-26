variable "resource_name_prefix" {
  type        = string
  description = "Prefix to give to names of infra created by this module, where applicable."
  default     = "worklytics-export-"
}

variable "worklytics_tenant_id" {
  type        = string
  description = "Numeric ID of your Worklytics tenant's service account (obtain from Worklytics App)."

  validation {
    condition     = var.worklytics_tenant_id == null || can(regex("^\\d{21}$", var.worklytics_tenant_id))
    error_message = "`worklytics_tenant_id` must be a 21-digit numeric value. (or `null`, for pre-production use case where you don't want external entity to be allowed to assume the role)."
  }
}

variable "enable_aws_s3_bucket_public_access_block" {
  type        = bool
  description = "Whether to place restrictive `aws_s3_bucket_public_access_block` on S3 bucket. Set to `false` if you wish to configure something equivalent outside this module."
  default     = true
}

variable "tags_for_all" {
  type        = map(string)
  description = "Tags to apply to all resources created by this module. If conflict with per-resource tags, resource values will take precedence."
  default     = {}
}

variable "s3_bucket_tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket"
  default     = {}
}

variable "iam_role_tags" {
  type        = map(string)
  description = "Tags to apply to the IAM role"
  default     = {}
}

variable "iam_policy_tags" {
  type        = map(string)
  description = "Tags to apply to the IAM policy"
  default     = {}
}
