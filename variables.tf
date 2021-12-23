
variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "account_id" {
  description = "ID account"
  type    = string
  default = "XXXXXXXXXX"
}

variable "tag_key" {
  description = "Tag Key"
  type    = string
  default = "Owner"
}
