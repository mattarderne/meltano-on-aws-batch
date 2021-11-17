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
  name = "aws-batch-meltano-role"
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
}

resource "aws_iam_role_policy_attachment" "instance-role" {
  role = aws_iam_role.instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance-role" {
  name = "aws-batch-meltano-role"
  role = aws_iam_role.instance-role.name
}

resource "aws_iam_role" "aws-batch-service-role" {
  name = "aws-batch-service-role"
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
}

resource "aws_iam_role_policy_attachment" "aws-batch-service-role" {
  role = aws_iam_role.aws-batch-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "meltano-batch" {
  name = "aws-batch-meltano-security-group"
  description = "AWS Batch Sample Security Group"
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = [ "0.0.0.0/0" ]
  }
}

resource "aws_batch_compute_environment" "meltano" {
  compute_environment_name = "meltano-sample"
  compute_resources {
    instance_role = aws_iam_instance_profile.instance-role.arn
    instance_type = [
      "optimal"
    ]
    max_vcpus = 6
    min_vcpus = 0
    security_group_ids = [aws_security_group.meltano-batch.id]
    subnets = data.aws_subnet_ids.all.ids
    type = "EC2"
  }
  service_role = aws_iam_role.aws-batch-service-role.arn
  type = "MANAGED"
  depends_on = [ aws_iam_role_policy_attachment.aws-batch-service-role ]
}

resource "aws_batch_job_queue" "meltano" {
  name = "meltano-queue"
  state = "ENABLED"
  priority = 1
  compute_environments = [ aws_batch_compute_environment.meltano.arn ]
}

resource "aws_ecr_repository" "meltano-job-repo" {
  name = "aws-batch-meltano-sample"
}

resource "aws_s3_bucket" "image-bucket" {
  bucket_prefix = "aws-batch-sample-"
}

resource "aws_iam_role" "job-role" {
  name = "aws-batch-meltano-job-role"
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
}

resource "aws_iam_policy" "job-policy" {
  name = "aws-batch-meltano-job-policy"
  path = "/BatchSample/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.image-bucket.arn}",
        "${aws_s3_bucket.image-bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "job-role" {
  role = aws_iam_role.job-role.name
  policy_arn = aws_iam_policy.job-policy.arn
}

resource "aws_batch_job_definition" "meltano-job" {
  name = "meltano-job"
  type = "container"
  depends_on = [
    aws_ecr_repository.meltano-job-repo,
    aws_s3_bucket.image-bucket,
  ]
  parameters = {
    bucketName = aws_s3_bucket.image-bucket.id
  }
  container_properties = <<CONTAINER_PROPERTIES
{
  "image": "${aws_ecr_repository.meltano-job-repo.repository_url}",
  "jobRoleArn": "${aws_iam_role.job-role.arn}",
  "vcpus": 2,
  "memory": 2000,
  "environment": [
    { "name": "AWS_REGION", "value": "${var.region}" }
  ],
  "command": [
    "elt"
  ]
}
CONTAINER_PROPERTIES
}

# ## lambda resource + iam
# resource "aws_iam_role" "lambda-role" {
#   name = "aws-batch-meltano-function-role"
#   path = "/BatchSample/"
#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement":
#     [
#       {
#           "Action": "sts:AssumeRole",
#           "Effect": "Allow",
#           "Principal": {
#             "Service": "lambda.amazonaws.com"
#           }
#       }
#     ]
# }
# EOF
# }

# resource "aws_iam_policy" "lambda-policy" {
#   name = "aws-batch-meltano-function-policy"
#   path = "/BatchSample/"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "batch:SubmitJob"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "lambda-service" {
#   role = aws_iam_role.lambda-role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_iam_role_policy_attachment" "lambda-policy" {
#   role = aws_iam_role.lambda-role.name
#   policy_arn = aws_iam_policy.lambda-policy.arn
# }

# resource "aws_lambda_function" "submit-job-function" {
#   function_name = "aws-batch-meltano-function"
#   filename = "lambda_function.zip"
#   role = aws_iam_role.lambda-role.arn
#   handler = "index.handler"
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#   runtime = "nodejs14.x"
#   depends_on = [ "aws_iam_role_policy_attachment.lambda-policy" ]
#   environment {
#     variables = {
#       JOB_DEFINITION = aws_batch_job_definition.meltano-job.arn
#       JOB_QUEUE = aws_batch_job_queue.meltano.arn
#       IMAGES_BUCKET = aws_s3_bucket.image-bucket.id
#     }
#   }
# }