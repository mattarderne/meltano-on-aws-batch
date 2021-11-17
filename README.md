# meltano-batch
Running Meltano ELT on AWS Batch, configured with terraform

## Prerequisites

To run the project, you will to:

1. Select an AWS Region. Be sure that all required services (e.g. AWS Batch, AWS Lambda) are available in the Region selected.
2. Install [Docker](https://docs.docker.com/install/).
3. Install [HashiCorp Terraform](https://www.terraform.io/intro/getting-started/install.html).
4. Install the latest version of the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and confirm it is [properly configured](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).


## Setup 


1. Setup terraform 

```
git clone git@github.com:mattarderne/meltano-batch.git
cd meltano-batch/terraform
vi secrets.tfvars
terraform init
```

2. Run terraform
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
$ docker tag aws-batch-image-processor-sample:latest <MY_REPO_NAME>:latest

# push the image to the repository
docker push <MY_REPO_NAME>:latest
```


