# variables needed by the example

variable "aws_account_id" {
  type        = string
  description = "AWS account in which to provision. Required to be explicitly specified, to reduce chance of inadvertently provisioning in the wrong account."
}

variable "aws_role_name" {
  type        = string
  description = "The name of the role to assume within AWS account. `null` if already auth'd as desired role/user."
  default     = null
}
