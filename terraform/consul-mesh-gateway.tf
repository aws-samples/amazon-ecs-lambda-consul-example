locals {
  mesh_gateway_service_name = "mesh-gateway"
}

module "mesh_gateway" {
  source  = "hashicorp/consul-ecs/aws//modules/gateway-task"
  version = "0.5.1"

  kind   = "mesh-gateway"
  family = local.mesh_gateway_service_name

  ecs_cluster_arn = aws_ecs_cluster.this.arn
  subnets         = local.private_subnets
  security_groups = [aws_security_group.consul_client.id]
  retry_join      = [module.dev_consul_server.server_dns]

  acls                          = true
  tls                           = true
  consul_server_ca_cert_arn     = module.dev_consul_server.ca_cert_arn
  gossip_key_secret_arn         = module.dev_consul_server.gossip_key_arn
  lb_enabled                    = true
  lb_subnets                    = local.public_subnets
  lb_vpc_id                     = local.vpc_id
  additional_task_role_policies = []

  consul_http_addr = local.consul_http_addr

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = local.mesh_gateway_service_name
    }
  }

  consul_image               = "${var.consul_image}:${var.consul_version}"
  consul_agent_configuration = <<EOF
connect {
  enabled = true,
  enable_serverless_plugin = true
}
EOF
}