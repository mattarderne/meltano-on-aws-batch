#!/bin/bash
NAME="meltano-elt"
AWS_ACCOUNT="<AWS ACCOUNT>"
REGION="eu-west-1"
TAG="meltano"

# NB: currently requires creation of an ECR, which Terraform creates

# Retrieve an authentication token and authenticate your Docker client to your registry.
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com

aws ecr create-repository --repository-name $NAME --region $REGION

# Build your Docker image using the following command. You could skip this step if your image is already built:
docker build -t $NAME:$TAG meltano/.

# After the build completes, tag your image so you can push the image to this repository
docker tag $NAME:$TAG $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$NAME:$TAG

# Push this image to your newly created AWS repository:
docker push $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$NAME:$TAG

