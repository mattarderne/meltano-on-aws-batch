variable "region" {
    default = "eu-west-1"
}

variable "aws_account" {
}

variable "prefix" {
    description = "TODO: Change this to whatever you'd like to prefix the project infrastructure"
    default = "pr"
}

variable "aws_profile" {
  description = "TODO: Change this to whatever your AWS CLI profile is saved as in ~/.aws/credentials"
  type        = string
  default     = "focal"
}

