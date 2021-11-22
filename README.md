# meltano-batch
Running Meltano ELT on AWS Batch, configured with terraform

## Prerequisites

1. Select an AWS Region. Be sure that all required services (e.g. AWS Batch, AWS Lambda) are available in the Region selected.
2. Install [Docker](https://docs.docker.com/install/).
3. Install [HashiCorp Terraform](https://www.terraform.io/intro/getting-started/install.html).
4. Install the latest version of the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and confirm it is [properly configured](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).


## Setup 


1. Setup terraform 

```
git clone git@github.com:mattarderne/meltano-batch.git
cd meltano-batch/terraform
terraform init
```

2. Run terraform, which will create all necessary infrastructure.
```
terraform plan 
terraform apply 
```

## Build and Push Docker Image

Once finished, Terraform will output the name of your newly created ECR Repository, e.g. 123456789098.dkr.ecr.us-east-1.amazonaws.com/aws-batch-image-processor-sample. Note this value as we will use it in subsequent steps (referred to as MY_REPO_NAME):

```bash
cd ..
cd meltano

# build the docker image
docker build -t aws-batch-meltano .

# test the docker image
docker run \
    --volume $(pwd)/output:/project/output \
    aws-batch-meltano \
    elt tap-smoke-test target-jsonl

# tag the image
$ docker tag aws-batch-meltano:latest <MY_REPO_NAME>:latest

# push the image to the repository
docker push <MY_REPO_NAME>:latest
```

Now go to AWS Batch and create a job from the job definition page
https://eu-west-1.console.aws.amazon.com/batch/home?region=eu-west-1#job-definition

# Meltano UI

Load the Meltano UI to have a look. Currently only for display purposes, but can be configured to display the meltano app and kick-off adhoc jobs. Using Apprunner (example in `terraform/archive/apprunner.tf`) is viable for deploying to production, but requires a backend DB to be configured in the Dockerfile.

```bash
docker run \
    --volume $(pwd)/output:/project/output \
    aws-batch-meltano \
    ui
```