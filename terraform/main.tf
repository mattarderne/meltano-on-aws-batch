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

# retrieves the default vpc for this region
data "aws_vpc" "default" {
  default = true
}

# retrieves the subnet ids in the default vpc
data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# helper to package the lambda function for deployment
# data "archive_file" "lambda_zip" {
#   type = "zip"
#   source_file = "lambda/index.js"
#   output_path = "lambda_function.zip"
# }


resource "aws_iam_role" "instance-role" {
  name = "${var.prefix}-role"
  path = "/BatchSample/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          }
      }
    ]
}
EOF
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_iam_role_policy_attachment" "instance-role" {
  role = aws_iam_role.instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance-role" {
  name = "${var.prefix}-role"
  role = aws_iam_role.instance-role.name
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_iam_role" "aws-batch-service-role" {
  name = "${var.prefix}-service-role"
  path = "/BatchSample/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "batch.amazonaws.com"
          }
      }
    ]
}
EOF

tags = {
    Project = var.prefix
    Env = var.env
 
  }
}

resource "aws_iam_role_policy_attachment" "aws-batch-service-role" {
  role = aws_iam_role.aws-batch-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "meltano-batch" {
  name = "${var.prefix}-security-group"
  description = "AWS Batch Security Group"
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = [ "0.0.0.0/0" ]
  }
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_batch_compute_environment" "meltano" {
  compute_environment_name = "${var.prefix}-compute"
  compute_resources {
    instance_role = aws_iam_instance_profile.instance-role.arn
    instance_type = [
      "optimal"
    ]
    max_vcpus = 6
    min_vcpus = 0
    security_group_ids = [ aws_security_group.meltano-batch.id ]
    subnets = data.aws_subnet_ids.all.ids
    type = "EC2"
  }
  service_role = aws_iam_role.aws-batch-service-role.arn
  type = "MANAGED"
  depends_on = [ aws_iam_role_policy_attachment.aws-batch-service-role ]
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_batch_job_queue" "meltano" {
  name = "${var.prefix}-queue"
  state = "ENABLED"
  priority = 1
  compute_environments = [ aws_batch_compute_environment.meltano.arn ]
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_ecr_repository" "meltano-job-repo" {
  name = "${var.prefix}-ecr-repo"
  
  tags = {
    Project = var.prefix
    Env = var.env
  }
  
}

resource "aws_iam_role" "job-role" {
  name = "${var.prefix}-job-role"
  path = "/BatchSample/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
          }
      }
    ]
}
EOF

tags = {
    Project = var.prefix
    Env = var.env
 
  }
}


# ## lambda resource + iam
resource "aws_iam_role" "lambda-role" {
  name = "${var.prefix}-function-role"
  path = "/BatchSample/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          }
      }
    ]
}
EOF

tags = {
    Project = var.prefix
    Env = var.env
 
  }
}

resource "aws_iam_policy" "lambda-policy" {
  name = "${var.prefix}-function-policy"
  path = "/BatchSample/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "batch:SubmitJob"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

tags = {
    Project = var.prefix
    Env = var.env
 
  }
}

resource "aws_iam_role_policy_attachment" "lambda-service" {
  role = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda-policy" {
  role = aws_iam_role.lambda-role.name
  policy_arn = aws_iam_policy.lambda-policy.arn
}
