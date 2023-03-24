variable "aws_account_id" {
  type        = string
  description = "AWS account in which to provision. Required to be explicitly specified, to reduce chance of inadvertently provisioning in the wrong account."
}

variable "aws_role_name" {
  type        = string
  description = "The name of the role to assume within AWS account. `null` if already auth'd as desired role/user."
  default     = null
}

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

