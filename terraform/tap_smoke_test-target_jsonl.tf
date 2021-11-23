# This file contains everything necessary to run a single job. Doing a Find/Replace on "job-smoke-test" should be sufficient to create a new job

# Set frequency of job
resource "aws_cloudwatch_event_rule" "frequency" {
  name                = "job-frequency"
  description         = "Determines the frequency of Job runs (day/hour/minute), can also be cron(0 20 * * ? *)."
  schedule_expression = "rate(1 ${var.job_frequency})"
  is_enabled          = true
tags = local.common_tags
}

# Configure Job by changing the "command" list
resource "aws_batch_job_definition" "job-smoke-test" {
  name = "job-smoke-test"
  type = "container"
  depends_on = [
    aws_ecr_repository.meltano-job-repo,
  ]
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
    "elt",
    "tap-smoke-test",
    "target-jsonl"
  ]
}
CONTAINER_PROPERTIES
tags = local.common_tags
}

  # "secrets": [{
  #     "name": "${var.environment_variable_name}",
  #     "valueFrom": "arn:aws:secretsmanager:region:aws_account_id:secret:secret_name-AbCdEf"
  #   }],

# Lambda to run the job
resource "aws_lambda_function" "submit-job-smoke-test" {
  function_name    = "submit-job-smoke-test"
  filename         = data.archive_file.lambda_zip.output_path
  role             = aws_iam_role.lambda-role.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.8"
  depends_on       = [aws_iam_role_policy_attachment.lambda-policy]
  environment {
    variables = {
      JOB_DEFINITION = aws_batch_job_definition.job-smoke-test.name
      JOB_QUEUE      = aws_batch_job_queue.meltano.name
      ALERT_WEBHOOK  = var.slack_webhook
      ALERT_TOGGLE   = var.slack_webhook_toggle
    }
  }
tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "create_job_frequency" {
  rule      = aws_cloudwatch_event_rule.frequency.name
  target_id = "lambda"
  arn       = aws_lambda_function.submit-job-smoke-test.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_create_job" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit-job-smoke-test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.frequency.arn
}