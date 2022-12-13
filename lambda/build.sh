#!/bin/bash

set -e

CONSUL_LAMBDA_EXTENSION_VERSION=0.1.0-beta2

mkdir -p terraform/artifacts
cd lambda/greeter/src && zip ../../../terraform/artifacts/greeter.zip index.js

cd ../../..

curl -L https://releases.hashicorp.com/consul-lambda-extension/${CONSUL_LAMBDA_EXTENSION_VERSION}/consul-lambda-extension_${CONSUL_LAMBDA_EXTENSION_VERSION}_linux_amd64.zip \
  --output terraform/artifacts/consul-lambda-extension.zip