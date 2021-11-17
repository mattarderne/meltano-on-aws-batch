terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.2"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

resource "aws_eip" "nat" {
  count = 1

  vpc = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-${var.vpc_name}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24"]


  enable_nat_gateway  = true
  single_nat_gateway  = true
  one_nat_gateway_per_az = false
  reuse_nat_ips       = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat.*.id        # <= IPs specified here as input to the module

# TODO: enables internet access to the DB, only necessary for development, 
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Terraform = "true"
    Project = "${var.prefix}-meltano"
  }
}


resource "aws_db_subnet_group" "subnet" {
  name       = "${var.prefix}-${var.subnet_name}"
  subnet_ids = module.vpc.public_subnets
}

resource "aws_security_group" "security_group" {
  name   = "${var.prefix}-${var.security_group_name}"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.access_ip_list
    # cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform = "true"
    Project = "${var.prefix}-meltano"
  }
}

resource "aws_db_parameter_group" "parameters" {
  name   = "${var.prefix}-${var.rds_parameters}"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "db_instance" {
  identifier             = var.rds_name
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "13.3"
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.subnet.name
  vpc_security_group_ids = [aws_security_group.security_group.id]
  parameter_group_name   = aws_db_parameter_group.parameters.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
  
  tags = {
    Terraform = "true"
    Project = "${var.prefix}-meltano"
  }
}

# resource "aws_elastic_beanstalk_application" "application" {
#   name        = var.eb_application_name
# }

# resource "aws_elastic_beanstalk_environment" "environment" {
#   name                = var.eb_environment_name
#   application         = aws_elastic_beanstalk_application.application.name
#   solution_stack_name = "64bit Amazon Linux 2 v3.4.8 running Docker"
#     setting {
#         namespace = "aws:autoscaling:launchconfiguration"
#         name      = "IamInstanceProfile"
#         value     = "aws-elasticbeanstalk-ec2-role"
#       }
# }

