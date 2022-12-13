module "lambda_registrator" {
  count   = var.deploy_consul_lambda ? 1 : 0
  source  = "hashicorp/consul-lambda-registrator/aws//modules/lambda-registrator"
  version = "0.1.0-beta2"

  name          = "${var.name}-consul-lambda-registrator"
  ecr_image_uri = "${aws_ecr_repository.consul_lambda_registrator.repository_url}:latest"

  consul_http_addr             = local.consul_http_addr
  consul_http_token_path       = aws_ssm_parameter.consul_acl_token.0.name
  consul_extension_data_prefix = "/${var.name}"

  security_group_ids = [aws_security_group.consul_client.id]
  subnet_ids         = local.private_subnets

  sync_frequency_in_minutes = 1
}

resource "aws_ssm_parameter" "consul_acl_token" {
  count = var.deploy_consul_lambda ? 1 : 0
  name  = "/lambda-registrator/acl-token"
  type  = "SecureString"
  value = data.aws_secretsmanager_secret_version.consul_bootstrap_token.secret_string
}