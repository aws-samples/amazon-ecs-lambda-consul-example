module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.4"

  name                 = var.name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

locals {
  private_subnets               = module.vpc.private_subnets
  public_subnets                = module.vpc.public_subnets
  vpc_id                        = module.vpc.vpc_id
  vpc_default_security_group_id = module.vpc.default_security_group_id
  vpc_arn                       = module.vpc.vpc_arn
}