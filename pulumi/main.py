import pulumi
import pulumi_aws as aws

# need to work out the data helper

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "lambda/lambda.py"
#   output_path = "lambda_function.zip"
# }

default = aws.ec2.get_vpc(default=True)
all = aws.ec2.get_subnet_ids(vpc_id=default.id)


instance_role_role = aws.iam.Role("instance-roleRole",
    path="/BatchSample/",
    assume_role_policy="""{
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
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
instance_role_role_policy_attachment = aws.iam.RolePolicyAttachment("instance-roleRolePolicyAttachment",
    role=instance_role_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role")
instance_role_instance_profile = aws.iam.InstanceProfile("instance-roleInstanceProfile",
    role=instance_role_role.name,
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
aws_batch_service_role_role = aws.iam.Role("aws-batch-service-roleRole",
    path="/BatchSample/",
    assume_role_policy="""{
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
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
aws_batch_service_role_role_policy_attachment = aws.iam.RolePolicyAttachment("aws-batch-service-roleRolePolicyAttachment",
    role=aws_batch_service_role_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole")
meltano_batch = aws.ec2.SecurityGroup("meltano-batch",
    description="AWS Batch Security Group",
    vpc_id=data["aws_vpc"]["default"]["id"],
    egress=[{
        "from_port": 0,
        "to_port": 65535,
        "protocol": "tcp",
        "cidr_blocks": ["0.0.0.0/0"],
    }],
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
meltano_compute_environment = aws.batch.ComputeEnvironment("meltanoComputeEnvironment",
    compute_environment_name=f"{var['prefix']}-compute",
    compute_resources={
        "instanceRole": instance_role_instance_profile.arn,
        "instance_types": ["optimal"],
        "maxVcpus": 6,
        "minVcpus": 0,
        "security_group_ids": [meltano_batch.id],
        "subnets": data["aws_subnet_ids"]["all"]["ids"],
        "type": "EC2",
    },
    service_role=aws_batch_service_role_role.arn,
    type="MANAGED",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    },
    opts=ResourceOptions(depends_on=[aws_batch_service_role_role_policy_attachment]))
meltano_job_queue = aws.batch.JobQueue("meltanoJobQueue",
    state="ENABLED",
    priority=1,
    compute_environments=[meltano_compute_environment.arn],
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
meltano_job_repo = aws.ecr.Repository("meltano-job-repo", tags={
    "Project": var["prefix"],
    "Env": var["env"],
})
job_role = aws.iam.Role("job-role",
    path="/BatchSample/",
    assume_role_policy="""{
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
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
# ## lambda resource + iam
lambda_role = aws.iam.Role("lambda-role",
    path="/BatchSample/",
    assume_role_policy="""{
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
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
lambda_policy_policy = aws.iam.Policy("lambda-policyPolicy",
    path="/BatchSample/",
    policy="""{
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
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
lambda_service = aws.iam.RolePolicyAttachment("lambda-service",
    role=lambda_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
lambda_policy_role_policy_attachment = aws.iam.RolePolicyAttachment("lambda-policyRolePolicyAttachment",
    role=lambda_role.name,
    policy_arn=lambda_policy_policy.arn)
