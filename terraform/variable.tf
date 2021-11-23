variable "region" {
  description = "TODO: Change this to your region default"
  default     = "eu-west-1"
}

variable "aws_account" {
  description = "Your AWS account number. Change this to your account number as a default to skip prompts"
  # default = "12354"
}

variable "job_frequency" {
  description = "Frequncy to run jobs (type day/hour/minute)"
}

variable "prefix" {
  description = "TODO: Change this to whatever you'd like to prefix the project infrastructure and set as the tags for the project"
  default     = "meltano-batch"
}

variable "env" {
  description = "TODO: Change this if you want to tag Prod version"
  default     = "DEV"
}

variable "aws_profile" {
  description = "TODO: Change this to whatever your AWS CLI profile is saved as in ~/.aws/credentials"
  type        = string
  default     = "focal"
}


variable "slack_webhook_toggle" {
  description = "TODO: Switch on the slack webhook by changing to 'true'. Requires slack_webhook to be populated"
  type        = string
  default     = "false"
}

variable "slack_webhook" {
  description = "TODO: Change the secret.tfvars to include a slack webhook for notifications from Lambda"
  type        = string
  default     = ""
}