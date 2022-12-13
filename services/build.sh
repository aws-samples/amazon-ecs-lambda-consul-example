#!/bin/bash

set -e

CONSUL_LAMBDA_REGISTRATOR_VERSION=0.1.0-beta2

## Build and push images to Amazon ECR for greeter, greeting, name, and ingress
AWS_REGION=$(cd terraform && terraform output -raw aws_region)
AWS_ACCOUNT_ID=$(cd terraform && terraform output -raw aws_account_id)

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

GREETING=$(cd terraform && terraform output -raw ecr_repository_url_greeting)
NAME=$(cd terraform && terraform output -raw ecr_repository_url_name)
GREETER=$(cd terraform && terraform output -raw ecr_repository_url_greeter)
INGRESS=$(cd terraform && terraform output -raw ecr_repository_url_ingress)

docker build -f services/greeting/src/Dockerfile -t $GREETING services/greeting/src
docker build -f services/name/src/Dockerfile -t $NAME services/name/src
docker build -f services/greeter/src/Dockerfile -t $GREETER services/greeter/src
docker build -f services/ingress/src/Dockerfile -t $INGRESS services/ingress/src

docker push $GREETING
docker push $NAME
docker push $GREETER
docker push $INGRESS

CONSUL_LAMBDA_REGISTRATOR=$(cd terraform && terraform output -raw ecr_repository_url_consul_lambda_registrator)

docker pull public.ecr.aws/hashicorp/consul-lambda-registrator:$CONSUL_LAMBDA_REGISTRATOR_VERSION
docker tag public.ecr.aws/hashicorp/consul-lambda-registrator:$CONSUL_LAMBDA_REGISTRATOR_VERSION $CONSUL_LAMBDA_REGISTRATOR
docker push $CONSUL_LAMBDA_REGISTRATOR