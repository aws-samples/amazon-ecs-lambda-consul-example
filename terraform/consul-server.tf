resource "random_uuid" "consul_token" {}

resource "aws_secretsmanager_secret" "consul_token" {
  name                    = "${var.name}-bootstrap-token"
  recovery_window_in_days = 0
  #checkov:skip=CKV_AWS_149:use AWS managed key for demo purpose
}

resource "aws_secretsmanager_secret_version" "consul_token" {
  secret_id     = aws_secretsmanager_secret.consul_token.id
  secret_string = random_uuid.consul_token.result
}

# Run the Consul dev server as an ECS task.
module "dev_consul_server" {
  depends_on = [
    module.vpc,
    aws_secretsmanager_secret_version.consul_token
  ]

  source  = "hashicorp/consul-ecs/aws//modules/dev-server"
  version = "0.5.1"

  name                        = "${var.name}-consul-server"
  ecs_cluster_arn             = aws_ecs_cluster.this.arn
  subnet_ids                  = local.private_subnets
  vpc_id                      = local.vpc_id
  lb_enabled                  = true
  lb_subnets                  = local.public_subnets
  lb_ingress_rule_cidr_blocks = var.ingress_cidrs

  tls                       = true
  gossip_encryption_enabled = true

  acls                     = true
  generate_bootstrap_token = false
  bootstrap_token_arn      = aws_secretsmanager_secret_version.consul_token.arn
  bootstrap_token          = aws_secretsmanager_secret_version.consul_token.secret_string


  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "consul-server"
    }
  }

  launch_type  = "FARGATE"
  consul_image = "${var.consul_image}:${var.consul_version}"
}

resource "random_pet" "controller" {}

locals {
  acl_controller_prefix   = "${var.name}-${random_pet.controller.id}"
  consul_http_addr        = "http://${module.dev_consul_server.server_dns}:8500"
  consul_public_http_addr = "http://${module.dev_consul_server.lb_dns_name}:8500"
}

module "consul_acl_controller" {
  depends_on = [
    module.dev_consul_server
  ]

  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "0.5.1"

  consul_bootstrap_token_secret_arn = module.dev_consul_server.bootstrap_token_secret_arn
  consul_server_http_addr           = local.consul_http_addr
  ecs_cluster_arn                   = aws_ecs_cluster.this.arn
  name_prefix                       = local.acl_controller_prefix
  region                            = var.region
  subnets                           = local.private_subnets
  security_groups                   = [local.vpc_default_security_group_id]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }

  launch_type = "FARGATE"
}

resource "aws_security_group_rule" "consul_server_ingress" {
  description              = "Access to Consul dev server from default security group"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = local.vpc_default_security_group_id
  security_group_id        = module.dev_consul_server.security_group_id
}