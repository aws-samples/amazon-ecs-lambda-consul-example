module "name" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "0.5.1"

  family = "name"
  container_definitions = [
    {
      name      = "name"
      image     = var.name_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      cpu         = 256
      memory      = 512
      mountPoints = []
      volumesFrom = []
      healthCheck = {
        interval = 60
        retries  = 3
        timeout  = 10
        command  = ["CMD-SHELL", "curl -f http://127.0.0.1:3000/health || exit 1"]
      }
      logConfiguration = local.name_log_config
    }
  ]

  cpu    = 512
  memory = 1024

  log_configuration                  = local.name_log_config
  additional_execution_role_policies = local.additional_execution_role_policies

  port                      = 3000
  retry_join                = [var.consul_server_attributes.server_dns]
  acls                      = true
  consul_http_addr          = var.consul_server_attributes.http_addr
  consul_server_ca_cert_arn = var.consul_server_attributes.ca_cert_arn
  gossip_key_secret_arn     = var.consul_server_attributes.gossip_key_arn
  tls                       = true

  consul_image               = var.consul_image
  consul_agent_configuration = <<EOF
connect {
  enabled = true,
  enable_serverless_plugin = true
}
EOF
}

resource "aws_ecs_service" "name" {
  name            = "name"
  cluster         = var.ecs_cluster_arn
  task_definition = module.name.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}
