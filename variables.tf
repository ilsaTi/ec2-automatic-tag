
variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "ca-central-1"
}

variable "account_id" {
  description = "ID account"
  type    = string
  default = "883353368571"
}

variable "tag_key" {
  description = "Tag Key"
  type    = string
  default = "Owner"
}
