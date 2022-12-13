variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "greetings"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "ingress_cidrs" {
  description = "Your IP. This is used in the load balancer security groups to ensure only you can access the Consul UI and example application."
  type        = list(string)
}

variable "ec2_key_pair_name" {
  description = "Name of keypair to log into EC2 instances"
  type        = string
}

variable "consul_image" {
  description = "Consul image to use for ECS"
  type        = string
  default     = "public.ecr.aws/hashicorp/consul"
}

variable "consul_version" {
  description = "Version of Consul to use"
  type        = string
  default     = "1.12.6"
}

variable "envoy_version" {
  description = "Version of Envoy to use. Check https://www.consul.io/docs/connect/proxies/envoy"
  type        = string
  default     = "1.22.2"
}

variable "deploy_ecs_services" {
  description = "Deploy ECS services after pushing images"
  type        = bool
  default     = false
}

variable "deploy_consul_lambda" {
  description = "Deploy Consul Lambda Registrator"
  type        = bool
  default     = false
}

variable "deploy_lambda" {
  description = "Deploy Lambda to start greeter migration"
  type        = bool
  default     = false
}

variable "migrate_to_lambda" {
  description = "Migrate all traffic to greeter lambda"
  type        = bool
  default     = false
}