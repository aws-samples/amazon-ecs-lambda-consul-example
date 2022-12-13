terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.34"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = var.name
    }
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

provider "consul" {
  address = local.consul_public_http_addr
  token   = data.aws_secretsmanager_secret_version.consul_bootstrap_token.secret_string
}