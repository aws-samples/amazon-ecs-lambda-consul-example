resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion"
  vpc_id      = local.vpc_id
  description = "SG for bastion host"
}

resource "aws_security_group_rule" "bastion_inbound" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
  security_group_id = aws_security_group.bastion.id
  description       = "Access to instances from external IP address"
}

resource "aws_security_group_rule" "bastion_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow outbound access"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.ubuntu_1804_ami_id.value
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = local.public_subnets.0
  #checkov:skip=CKV_AWS_88:bastion requires public IP
  associate_public_ip_address = true
  monitoring                  = true
  ebs_optimized               = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_size           = "20"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  tags = { "Name" = "${var.name}-bastion" }
}