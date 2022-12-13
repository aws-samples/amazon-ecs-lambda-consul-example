resource "aws_lambda_layer_version" "consul_lambda_extension" {
  layer_name       = "consul-lambda-extension"
  filename         = var.consul_lambda_extension_file_path
  source_code_hash = filebase64sha256(var.consul_lambda_extension_file_path)
  description      = "Consul service mesh extension for AWS Lambda"
}

resource "aws_lambda_function" "greeter" {
  function_name = "greeter-lambda"

  filename         = var.greeter_lambda_file_path
  source_code_hash = filebase64sha256(var.greeter_lambda_file_path)

  package_type = "Zip"
  handler      = "index.handler"
  runtime      = "nodejs16.x"

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      NAME_URL     = "http://localhost:${var.name_port}"
      GREETING_URL = "http://localhost:${var.greeting_port}"

      CONSUL_EXTENSION_DATA_PREFIX = "/${var.name}"
      CONSUL_MESH_GATEWAY_URI      = var.mesh_gateway_uri
      CONSUL_SERVICE_UPSTREAMS     = "name:${var.name_port},greeting:${var.greeting_port}"
    }
  }

  layers = [aws_lambda_layer_version.consul_lambda_extension.arn]

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }

  tracing_config {
    mode = "Active"
  }

  reserved_concurrent_executions = 10

  tags = {
    "serverless.consul.hashicorp.com/v1alpha1/lambda/enabled"             = "true"
    "serverless.consul.hashicorp.com/v1alpha1/lambda/payload-passthrough" = "true"
    "serverless.consul.hashicorp.com/v1alpha1/lambda/invocation-mode"     = "ASYNCHRONOUS"
  }
  #checkov:skip=CKV_AWS_116:skip DLQ, no data lost if Lambda failed
  #checkov:skip=CKV_AWS_173:no sensitive data in Lambda Env Variable
  #checkov:skip=CKV_AWS_272:no code signing for this demo purpose
}