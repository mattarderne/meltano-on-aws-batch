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

variable "access_ip_list" {
  description = "TODO: Change the secret.tfvars to include the VPN IP Address and local IP address"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the AWS VPC"
  type        = string
  default     = "meltano-vpc"
}

variable "subnet_name" {
  description = "Name of the AWS Subnet"
  type        = string
  default     = "meltano-subnet"
}

variable "security_group_name" {
  description = "Name of the AWS Security Group"
  type        = string
  default     = "meltano-security-group"
}

variable "rds_name" {
  description = "Name of the AWS RDS instance"
  type        = string
  default     = "meltano"
}

variable "db_name" {
  description = "Name of the AWS RDS database name"
  type        = string
  default     = "meltano"
}

variable "rds_parameters" {
  description = "AWS RDS instance parameters name"
  type        = string
  default     = "parameters"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
