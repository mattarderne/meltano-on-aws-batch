import pulumi
import pulumi_aws as aws

# Set frequency of job
frequency = aws.cloudwatch.EventRule("frequency",
    description="Determines the frequency of Job runs (day/hour/minute), can also be cron(0 20 * * ? *).",
    schedule_expression="rate(1 hour)",
    is_enabled=True,
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    })
# Configure Job by changing the "command" list

job_smoke_test = aws.batch.JobDefinition("job-smoke-test",
    type="container",
    container_properties=f"""{{
  "image": "{aws_ecr_repository["meltano-job-repo"]["repository_url"]}",
  "jobRoleArn": "{aws_iam_role["job-role"]["arn"]}",
  "vcpus": 2,
  "memory": 2000,
  "environment": [
    {{ "name": "AWS_REGION", "value": "{var["region"]}" }}
  ],
  "command": [
    "elt",
    "tap-smoke-test",
    "target-jsonl"
  ]
}}
""",
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    },
    opts=ResourceOptions(depends_on=[aws_ecr_repository["meltano-job-repo"]]))

# Lambda to run the job
submit_job_smoke_test = aws.lambda_.Function("submit-job-smoke-test",
    code=pulumi.FileArchive(data["archive_file"]["lambda_zip"]["output_path"]),
    role=aws_iam_role["lambda-role"]["arn"],
    handler="lambda.lambda_handler",
    runtime="python3.8",
    environment={
        "variables": {
            "JOB_DEFINITION": job_smoke_test.name,
            "JOB_QUEUE": aws_batch_job_queue["meltano"]["name"],
            "ALERT_WEBHOOK": var["slack_webhook"],
            "ALERT_TOGGLE": var["slack_webhook_toggle"],
        },
    },
    tags={
        "Project": var["prefix"],
        "Env": var["env"],
    },
    opts=ResourceOptions(depends_on=[aws_iam_role_policy_attachment["lambda-policy"]]))
create_job_frequency = aws.cloudwatch.EventTarget("createJobFrequency",
    rule=frequency.name,
    arn=submit_job_smoke_test.arn)
allow_cloudwatch_to_call_create_job = aws.lambda_.Permission("allowCloudwatchToCallCreateJob",
    action="lambda:InvokeFunction",
    function=submit_job_smoke_test.name,
    principal="events.amazonaws.com",
    source_arn=frequency.arn)
