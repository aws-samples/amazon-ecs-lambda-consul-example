variable "greeting_image" {
  type        = string
  description = "Image for greeting service"
}

variable "name_image" {
  type        = string
  description = "Image for name service"
}

variable "greeter_image" {
  type        = string
  description = "Image for greeter service"
}

variable "ingress_image" {
  type        = string
  description = "Image for ingress service"
}

variable "consul_image" {
  type        = string
  description = "Consul image to use"
}

variable "consul_server_attributes" {
  type = object({
    server_dns     = string
    http_addr      = string
    ca_cert_arn    = string
    gossip_key_arn = string
  })
  description = "Attributes required for services to register to Consul service mesh"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS Cluster ARN"
}

variable "alb_target_group_arn" {
  type        = string
  description = "Target Group ARN for ingress to attach to ALB"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnets to deploy greeter and name service"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnets to deploy greeting and ingress services"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to deploy services"
}

variable "ingress_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for ingress service"
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "Cloudwatch log group name"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "additional_execution_role_policies" {
  type        = list(string)
  description = "Additional execution role policies required"
  default     = []
}

variable "additional_task_role_policies_ingress" {
  type        = list(string)
  description = "Additional task role policies required for ingress to invoke greeter lambda"
  default     = []
}

locals {
  default_policies = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]

  additional_execution_role_policies    = concat(local.default_policies, var.additional_execution_role_policies)
  additional_task_role_policies_ingress = var.additional_task_role_policies_ingress

  greeting_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = "greeting"
    }
  }

  name_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = "name"
    }
  }

  greeter_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = "greeter"
    }
  }

  ingress_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = "ingress"
    }
  }
}