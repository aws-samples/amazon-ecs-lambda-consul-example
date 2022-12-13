module "greeter_lambda" {
  count                             = var.deploy_lambda ? 1 : 0
  source                            = "./lambda"
  name                              = var.name
  greeter_lambda_file_path          = "${path.module}/artifacts/greeter.zip"
  consul_lambda_extension_file_path = "${path.module}/artifacts/consul-lambda-extension.zip"
  security_group_ids                = [aws_security_group.greeter_lambda[count.index].id]
  subnet_ids                        = local.private_subnets
  mesh_gateway_uri                  = "${module.mesh_gateway.wan_address}:${module.mesh_gateway.wan_port}"
}

resource "aws_security_group" "greeter_lambda" {
  #checkov:skip=CKV2_AWS_5:suppress false warning since this resource is passed to the module
  count       = var.deploy_lambda ? 1 : 0
  name        = "${var.name}-greeter-lambda"
  vpc_id      = local.vpc_id
  description = "SG for Greeter lambda function"
}

resource "aws_security_group_rule" "terminating_gateway_to_lambda" {
  count                    = var.deploy_lambda ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.terminating_gateway.id
  security_group_id        = aws_security_group.greeter_lambda[count.index].id
  description              = "Allow ingress from consul server to the Terminating gateway"
}

resource "aws_security_group_rule" "greeter_lambda_outbound" {
  count                    = var.deploy_lambda ? 1 : 0
  type                      = "egress"
  from_port                 = 0
  to_port                   = 0
  protocol                  = "-1"
  cidr_blocks               = ["0.0.0.0/0"]
  security_group_id         = aws_security_group.greeter_lambda[count.index].id
  description               = "Allow outbound access"
}