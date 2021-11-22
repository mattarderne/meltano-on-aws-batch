resource "aws_batch_job_definition" "meltano-job" {
  name = "meltano-smoke-test-job"
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
    "tap-smoke-test",
    "target-jsonl"
  ]
}
CONTAINER_PROPERTIES
}

####
#### Lambda to trigger job running
####

resource "aws_lambda_function" "submit-smoke-test-job" {
  function_name = "submit-smoke-test-job"
  filename = data.archive_file.lambda_zip.output_path
  role = aws_iam_role.lambda-role.arn
  handler = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime = "python3.8"
  depends_on = [ aws_iam_role_policy_attachment.lambda-policy ]
  environment {
    variables = {
      JOB_DEFINITION = aws_batch_job_definition.meltano-playlist-stitch-job.name
      JOB_QUEUE = aws_batch_job_queue.meltano.name
      ALERT_WEBHOOK = var.slack_webhook
      ALERT_TOGGLE = var.slack_webhook_toggle
    }
  }
}

# Lambda Trigger 


resource "aws_cloudwatch_event_rule" "frequency" {
  name                = "job-frequency"
  description         = "Fires every one day"
  schedule_expression = "rate(1 day)"
  is_enabled          = true
}


resource "aws_cloudwatch_event_target" "create_job_frequency" {
  rule      = aws_cloudwatch_event_rule.frequency.name
  target_id = "lambda"
  arn       = aws_lambda_function.submit-smoke-test-job.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_create_job" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit-smoke-test-job.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.frequency.arn
}