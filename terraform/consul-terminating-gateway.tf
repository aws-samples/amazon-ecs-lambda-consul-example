locals {
  terminating_gateway_service_name = "terminating-gateway"
}

data "aws_ssm_parameter" "ubuntu_1804_ami_id" {
  name = "/aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_secretsmanager_secret_version" "consul_ca_key" {
  secret_id = module.dev_consul_server.ca_key_arn
}

data "aws_secretsmanager_secret_version" "consul_ca_cert" {
  secret_id = module.dev_consul_server.ca_cert_arn
}

data "aws_secretsmanager_secret_version" "consul_gossip_key" {
  secret_id = module.dev_consul_server.gossip_key_arn
}

data "aws_secretsmanager_secret_version" "consul_bootstrap_token" {
  secret_id = module.dev_consul_server.bootstrap_token_secret_arn
}

resource "tls_private_key" "terminating_gateway_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

## Terminating Gateway Public Client Cert
resource "tls_cert_request" "terminating_gateway_cert" {
  private_key_pem = tls_private_key.terminating_gateway_key.private_key_pem

  subject {
    common_name  = "${local.terminating_gateway_service_name}.dc1.consul"
    organization = "HashiCorp Inc."
  }

  dns_names = [
    "${local.terminating_gateway_service_name}.dc1.consul",
    "localhost"
  ]

  ip_addresses = ["127.0.0.1"]
}

## Terminating Gateway Signed Public Client Certificate
resource "tls_locally_signed_cert" "terminating_gateway_signed_cert" {
  cert_request_pem = tls_cert_request.terminating_gateway_cert.cert_request_pem

  ca_private_key_pem = data.aws_secretsmanager_secret_version.consul_ca_key.secret_string
  ca_cert_pem        = data.aws_secretsmanager_secret_version.consul_ca_cert.secret_string

  allowed_uses = [
    "digital_signature",
    "key_encipherment"
  ]

  validity_period_hours = 8760
}

resource "aws_iam_instance_profile" "terminating_gateway" {
  name = "${var.name}-terminating-gateway"
  role = aws_iam_role.terminating_gateway.name
}

resource "aws_iam_role" "terminating_gateway" {
  name = "terminating-gateway"
  path = "/${var.name}/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "invoke_lambda" {
  name   = "ecs-invoke-lambda"
  path   = "/${var.name}/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:greeter-lambda"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "terminating_gateway_lambda" {
  role       = aws_iam_role.terminating_gateway.name
  policy_arn = aws_iam_policy.invoke_lambda.arn
}

resource "aws_instance" "consul_terminating_gateway" {
  depends_on = [
    module.dev_consul_server,
    module.consul_acl_controller,
    module.mesh_gateway
  ]

  ami                    = data.aws_ssm_parameter.ubuntu_1804_ami_id.value
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.terminating_gateway.id, aws_security_group.consul_client.id]
  subnet_id              = local.private_subnets.0

  iam_instance_profile = aws_iam_instance_profile.terminating_gateway.name

  user_data = base64encode(templatefile("${path.module}/scripts/terminating-gateway.sh", {
    SERVICE_NAME       = local.terminating_gateway_service_name
    CONSUL_VERSION     = "${var.consul_version}-1"
    ENVOY_VERSION      = var.envoy_version
    CONSUL_ADDR        = module.dev_consul_server.server_dns
    GOSSIP_KEY         = data.aws_secretsmanager_secret_version.consul_gossip_key.secret_string
    BOOTSTRAP_TOKEN    = data.aws_secretsmanager_secret_version.consul_bootstrap_token.secret_string
    CA_PUBLIC_KEY      = data.aws_secretsmanager_secret_version.consul_ca_cert.secret_string
    CLIENT_PUBLIC_KEY  = tls_locally_signed_cert.terminating_gateway_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.terminating_gateway_key.private_key_pem
  }))

  monitoring    = true
  ebs_optimized = true

  #checkov:skip=CKV_AWS_79:envoy did not support IMDSv2 yet
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
  }

  root_block_device {
    volume_size           = "20"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.name}-consul-terminating-gateway" }
}

resource "consul_config_entry" "terminating_gateway" {
  count = var.deploy_lambda ? 1 : 0

  depends_on = [
    module.dev_consul_server,
    aws_instance.consul_terminating_gateway
  ]

  name = local.terminating_gateway_service_name
  kind = "terminating-gateway"

  config_json = jsonencode({
    Services = [
      {
        Name = "greeter-lambda"
      }
    ]
  })
}

resource "aws_security_group" "terminating_gateway" {
  name        = "${var.name}-terminating_gateway"
  vpc_id      = local.vpc_id
  description = "SG for Consul terminating gateway"
}

resource "aws_security_group_rule" "terminating_gateway_bastion" {
  type                      = "ingress"
  from_port                 = 22
  to_port                   = 22
  protocol                  = "tcp"
  source_security_group_id  = aws_security_group.bastion.id
  security_group_id         = aws_security_group.terminating_gateway.id
  description               = "Access from Bastion host"
}

resource "aws_security_group_rule" "terminating_gateway_outbound" {
  type                      = "egress"
  from_port                 = 0
  to_port                   = 0
  protocol                  = "-1"
  cidr_blocks               = ["0.0.0.0/0"]
  security_group_id         = aws_security_group.terminating_gateway.id
  description               = "Allow outbound access"
}