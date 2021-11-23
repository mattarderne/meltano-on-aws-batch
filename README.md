# meltano-batch
Running Meltano ELT on AWS Batch, infra with Terraform

## Prerequisites

1. Select an AWS Region. Be sure that all required services (e.g. AWS Batch, AWS Lambda) are available in the Region selected.
2. Install [Docker](https://docs.docker.com/install/).
3. Install [HashiCorp Terraform](https://www.terraform.io/intro/getting-started/install.html).
4. Install the latest version of the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and confirm it is [properly configured](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).

## Setup 

1. Setup terraform 
```bash
git clone git@github.com:mattarderne/meltano-batch.git
cd meltano-batch/terraform
terraform init
```

2. Run terraform, which will create all necessary infrastructure.
```bash
terraform plan 
terraform apply 
```

## Build and Push Docker Image

Once finished, Terraform will output the name of your newly created ECR Repository, e.g. `123456789.dkr.ecr.eu-west-1.amazonaws.com/meltano-batch-ecr-repo:latest` Note this value as we will use it in subsequent steps (referred to as MY_REPO_NAME):

```bash
cd ..
cd meltano

# build the docker image
docker build -t aws-batch-meltano .

# (optional) test the docker image
docker run \
    --volume $(pwd)/output:/project/output \
    aws-batch-meltano \
    elt tap-smoke-test target-jsonl

# tag the image
$ docker tag aws-batch-meltano:latest <MY_REPO_NAME>:latest

# login to the ECR, replace <region>
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <MY_REPO_NAME>

# push the image to the ECR repository
docker push <MY_REPO_NAME>:latest
```

The above scripts are automated in the `meltano/deploy_aws_ecr.sh` script

# Create a Job

Now that the docker image has been deployed to the ECR, you can invoke a job with the below, which will print the logs. Replace `<region>`

```bash
aws lambda invoke --function-name submit-job-smoke-test  --region <region> \
outfile --log-type Tail \
--query 'LogResult' --output text |  base64 -d
```

You should be able to view a list of the jobs with below command. (_returns an empty list, no idea why, please let me know if you do!_)
```bash
aws batch list-jobs --job-queue meltano-batch-queue 
```

# Meltano UI

Load the Meltano UI to have a look. Currently only for display purposes, but can be configured to display the meltano app and kick-off adhoc jobs. Using Apprunner (example in `terraform/archive/apprunner.tf`) is viable for deploying to production, but requires a backend DB to be configured in the Dockerfile.

```bash
docker run \
    --volume $(pwd)/output:/project/output \
    aws-batch-meltano \
    ui
```

# Notifications

By default there are no notifications set. Ideally this should be set by an AWS SNS system.

There is the capability to turn on Slack notifications as follows, 

1. Change the below line in `elt_tap_smoke_test-target_jsonl.tf`:
`handler          = "lambda.lambda_handler"`
to
`handler          = "alerts.lambda_handler"`
1. Change the below line in `main.py`:
`source_file = "lambda/lambda.py"`
to
`source_file = "alerts/lambda.py"`
1. Create a [slack webhook](https://api.slack.com/messaging/webhooks) create a `secret.tfvars` file in the `lambda` directory, adding the webhook url
```
slack_webhook = "<slack_webook>"
```
1. Change the `var.slack_webhook_toggle` in `variables.tf` file to `true` (lowercase)
1. Install `requests` in the `terraform/lambda` directory
```bash
cd terraform #must be run in terraform
pip install --target ./lambda requests
```
1. Run `terraform apply -var-file="secret.tfvars"`

Test with `aws lambda ...` command above. It should ping to slack. 
However it only is pinging when the job starts (or fails to start), not the outcome of the job. Proper setup should be with AWS Batch [SNS Notifications](https://docs.aws.amazon.com/batch/latest/userguide/batch_sns_tutorial.html)


# Todo

- [ ] setup a serverless DB to capture state files for incremental loads
- [ ] work out SNS
- [ ] work out SNS in Terraform
- [ ] work out GCP equivalent
- [ ] Test AWS AppRunnner for frontend
- [ ] Look into VPC settings
- [ ] Look into Pulumi


