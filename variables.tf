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

variable "worklytics_host" {
  type        = string
  description = "host of worklytics instance where tenant resides. (e.g. app.worklytics.co for prod; but may differ for dev/staging)"
  default     = "app.worklytics.co"
}

variable "todos_as_outputs" {
  type        = bool
  description = "whether to render TODOs as outputs (former useful if you're using Terraform Cloud/Enterprise, or somewhere else where the filesystem is not readily accessible to you)"
  default     = false
}

variable "todos_as_local_files" {
  type        = bool
  description = "whether to render TODOs as flat files"
  default     = true
}
