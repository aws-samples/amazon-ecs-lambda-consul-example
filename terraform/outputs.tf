output "consul_server_lb_address" {
  value       = local.consul_public_http_addr
  description = "Address to access Consul Server UI"
}

output "ingress_lb_address" {
  value       = "http://${aws_lb.ingress.dns_name}:8080"
  description = "Address to access Consul Server UI"
}

output "consul_bootstrap_token" {
  value     = data.aws_secretsmanager_secret_version.consul_bootstrap_token.secret_string
  sensitive = true
}

output "ecr_repository_url_greeting" {
  value       = aws_ecr_repository.greeting.repository_url
  sensitive   = true
  description = "ECR Repository for greeting service"
}

output "ecr_repository_url_name" {
  value       = aws_ecr_repository.name.repository_url
  sensitive   = true
  description = "ECR Repository for name service"
}

output "ecr_repository_url_greeter" {
  value       = aws_ecr_repository.greeter.repository_url
  sensitive   = true
  description = "ECR Repository for greeter service"
}

output "ecr_repository_url_ingress" {
  value       = aws_ecr_repository.ingress.repository_url
  sensitive   = true
  description = "ECR Repository for ingress service"
}

output "ecr_repository_url_consul_lambda_registrator" {
  value       = aws_ecr_repository.consul_lambda_registrator.repository_url
  sensitive   = true
  description = "ECR Repository for Consul lambda registrator"
}

output "aws_region" {
  value       = var.region
  description = "Region with resources"
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
  description = "AWS Account ID"
}