import pulumi

config = pulumi.Config()
region = config.get("region")
if region is None:
    region = "eu-west-1"
aws_account = config.require_object("awsAccount")
prefix = config.get("prefix")
if prefix is None:
    prefix = "meltano-batch"
env = config.get("env")
if env is None:
    env = "DEV"
aws_profile = config.get("awsProfile")
if aws_profile is None:
    aws_profile = "focal"
slack_webhook_toggle = config.get("slackWebhookToggle")
if slack_webhook_toggle is None:
    slack_webhook_toggle = "false"
slack_webhook = config.get("slackWebhook")
if slack_webhook is None:
    slack_webhook = ""
