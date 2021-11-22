#!/bin/bash
REGION="eu-west-1"
TAG="latest"
ECR_REPOSITORY="579337656087.dkr.ecr.eu-west-1.amazonaws.com/meltano-batch-ecr-repo"
# Get the ECR_REPOSITORY from the output of the Terraform apply command

# Retrieve an authentication token and authenticate your Docker client to your registry.
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

# Build your Docker image using the following command. You could skip this step if your image is already built:
docker build -t aws-batch-meltano .

# After the build completes, tag your image so you can push the image to this repository
docker tag aws-batch-meltano:$TAG $ECR_REPOSITORY:$TAG

# Push this image to your newly created AWS repository:
docker push $ECR_REPOSITORY:$TAG

