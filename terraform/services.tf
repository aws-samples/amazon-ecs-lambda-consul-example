module "services" {
  count = var.deploy_ecs_services ? 1 : 0

  depends_on = [
    module.dev_consul_server,
    module.consul_acl_controller
  ]

  source         = "./services"
  greeting_image = aws_ecr_repository.greeting.repository_url
  name_image     = aws_ecr_repository.name.repository_url
  greeter_image  = aws_ecr_repository.greeter.repository_url
  ingress_image  = aws_ecr_repository.ingress.repository_url

  consul_image = "${var.consul_image}:${var.consul_version}"

  consul_server_attributes = {
    server_dns     = module.dev_consul_server.server_dns
    http_addr      = local.consul_http_addr
    ca_cert_arn    = module.dev_consul_server.ca_cert_arn
    gossip_key_arn = module.dev_consul_server.gossip_key_arn
  }

  ecs_cluster_arn = aws_ecs_cluster.this.arn
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  security_group_ids = [
    aws_security_group.consul_client.id,
  ]
  ingress_security_group_ids = [
    aws_security_group.ingress_service.id
  ]

  cloudwatch_log_group_name = aws_cloudwatch_log_group.log_group.name
  alb_target_group_arn      = aws_lb_target_group.ingress.arn
  region                    = var.region

  additional_task_role_policies_ingress = [
    aws_iam_policy.execute_command.arn
  ]
}

resource "aws_security_group" "consul_client" {
  #checkov:skip=CKV2_AWS_5:suppress false warning since this resource is passed to the module
  name        = "${var.name}-consul-client"
  vpc_id      = local.vpc_id
  description = "SG for all consul client in the mesh"
}

resource "aws_security_group_rule" "consul_mesh_gateway_tcp" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow TCP for Consul mesh gateway"
}

resource "aws_security_group_rule" "consul_proxy_tcp" {
  type                     = "ingress"
  from_port                = 20000
  to_port                  = 20000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow TCP between all Consul proxies"
}

resource "aws_security_group_rule" "consul_client_gossip_tcp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow LAN gossip between all Consul client"
}

resource "aws_security_group_rule" "consul_client_gossip_udp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "udp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow LAN gossip between all Consul client"
}

resource "aws_security_group_rule" "consul_server_to_client_tcp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "tcp"
  source_security_group_id = module.dev_consul_server.security_group_id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow LAN gossip from Consul server to the Consul client"
}

resource "aws_security_group_rule" "consul_server_to_client_udp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "udp"
  source_security_group_id = module.dev_consul_server.security_group_id
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow LAN gossip from Consul server to the Consul client"
}

resource "aws_security_group_rule" "consul_client_outbound" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.consul_client.id
  description              = "Allow outbound for consul client"
}

resource "aws_security_group_rule" "client_to_consul_server_rpc" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8300
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = module.dev_consul_server.security_group_id
  description              = "Access to Consul dev server RPC from Consul client"
}

resource "aws_security_group_rule" "client_to_consul_server_api" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = module.dev_consul_server.security_group_id
  description              = "Access to Consul dev server API from Cconsul client"
}

resource "aws_security_group_rule" "client_to_consul_server_gossip_tcp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = module.dev_consul_server.security_group_id
  description              = "Allow LAN gossip between Consul client and Consul server"
}

resource "aws_security_group_rule" "client_to_consul_server_gossip_udp" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "udp"
  source_security_group_id = aws_security_group.consul_client.id
  security_group_id        = module.dev_consul_server.security_group_id
  description              = "Allow LAN gossip between Consul client and Consul server"
}

resource "aws_security_group" "ingress_service" {
  #checkov:skip=CKV2_AWS_5:suppress false warning since this resource is passed to the module
  name        = "${var.name}-ingress-services"
  vpc_id      = local.vpc_id
  description = "SG for Ingress service for external access"
}

resource "aws_security_group_rule" "alb_to_ingress_service" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ingress_alb.id
  security_group_id        = aws_security_group.ingress_service.id
  description              = "Allow incoming traffic from ALB to Ingress service"
}

resource "aws_security_group_rule" "ingress_service_to_outbound" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.ingress_service.id
  description              = "Allow outbond traffic to outbound ALB / internet"
}