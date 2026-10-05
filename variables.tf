variable "resource_name_prefix" {
  type        = string
  description = "Prefix to give to names of infra created by this module, where applicable. When `bucket_name` is unset, also used to generate a unique S3 bucket name via `bucket_prefix`."
  default     = "worklytics-export-"
}

variable "bucket_name" {
  type        = string
  description = "Fixed name for the export S3 bucket. When set, the module uses this exact bucket name instead of generating one from `resource_name_prefix`. Required when adopting an existing bucket (together with `terraform import`)."
  default     = null

  validation {
    condition = var.bucket_name == null || (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name)) &&
      !can(regex("\\.\\.", var.bucket_name)) &&
      !can(cidrhost("${var.bucket_name}/32", 0))
    )
    error_message = "`bucket_name` must be a valid S3 bucket name (3-63 lowercase characters, numbers, hyphens, or periods; must start and end with a letter or number) when set."
  }
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

variable "enable_aws_s3_bucket_versioning" {
  type        = bool
  description = "Whether to enable versioning on the export S3 bucket. Set to `false` if you wish to configure something equivalent outside this module."
  default     = false
}

variable "aws_s3_access_log_bucket" {
  type        = string
  description = "Optional destination bucket name for S3 server access logs of the export bucket. When `null`, access logging is not configured by this module (you may add `aws_s3_bucket_logging` yourself using the `worklytics_export_bucket` output)."
  default     = null
}

variable "aws_s3_access_log_prefix" {
  type        = string
  description = "Prefix for S3 server access log object keys. Only used when `aws_s3_access_log_bucket` is set."
  default     = "log/"
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
