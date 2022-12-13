module "ingress" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "0.5.1"

  family = "ingress"
  container_definitions = [
    {
      name      = "ingress"
      image     = var.ingress_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "GREETER_URL"
          value = "http://localhost:3000"
        }
      ]
      mountPoints = []
      volumesFrom = []
      healthCheck = {
        interval = 60
        retries  = 3
        timeout  = 10
        command  = ["CMD-SHELL", "curl -f http://127.0.0.1:8080/health || exit 1"]
      }
      logConfiguration = local.ingress_log_config
    }
  ]

  cpu    = 256
  memory = 512

  log_configuration                  = local.ingress_log_config
  additional_execution_role_policies = local.additional_execution_role_policies
  additional_task_role_policies      = local.additional_task_role_policies_ingress

  port                      = 8080
  retry_join                = [var.consul_server_attributes.server_dns]
  acls                      = true
  consul_http_addr          = var.consul_server_attributes.http_addr
  consul_server_ca_cert_arn = var.consul_server_attributes.ca_cert_arn
  gossip_key_secret_arn     = var.consul_server_attributes.gossip_key_arn
  tls                       = true

  upstreams = [
    {
      destinationName = "greeter"
      localBindPort   = 3000
    }
  ]

  consul_image               = var.consul_image
  consul_agent_configuration = <<EOF
connect {
  enabled = true,
  enable_serverless_plugin = true
}
EOF
}

resource "aws_ecs_service" "ingress" {
  name            = "ingress"
  cluster         = var.ecs_cluster_arn
  task_definition = module.ingress.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = concat(var.security_group_ids, var.ingress_security_group_ids)
    assign_public_ip = true
  }

  health_check_grace_period_seconds = 30

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "ingress"
    container_port   = 8080
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}
