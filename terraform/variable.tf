variable "region" {
    description = "TODO: Change this to your region default"
    default = "eu-west-1"
}

variable "aws_account" {
    description = "Your AWS account number. Change this to your account number as a default to skip prompts"
    # default = "12354"
}

variable "prefix" {
    description = "TODO: Change this to whatever you'd like to prefix the project infrastructure"
    default = "melt"
}

variable "aws_profile" {
  description = "TODO: Change this to whatever your AWS CLI profile is saved as in ~/.aws/credentials"
  type        = string
  default     = "focal"
}

