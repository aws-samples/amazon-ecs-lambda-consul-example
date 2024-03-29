terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.30.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = ">= 2.15.1"
    }
  }
}