resource "aws_lb" "ingress" {
  name                        = "${var.name}-ingress"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.ingress_alb.id]
  subnets                     = local.public_subnets
  drop_invalid_header_fields  = true
  #checkov:skip=CKV_AWS_150:disable delete protection to allow clean up
  #checkov:skip=CKV_AWS_91:disable access logging, demo purpose only
  #checkov:skip=CKV2_AWS_20:use HTTP only for demo purpose
  #checkov:skip=CKV2_AWS_28:skip WAF for this demo purpose
}

resource "aws_security_group" "ingress_alb" {
  name        = "${var.name}-ingress-alb"
  vpc_id      = local.vpc_id
  description = "SG for Ingress ALB"

  ingress {
    description = "Access to ingress nginx."
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  egress {
    description = "Allow outbound access to all IP space."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "ingress" {
  name                 = "${var.name}-ingress"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = local.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
  health_check {
    path                = "/health"
    interval            = 60
    unhealthy_threshold = 5
    healthy_threshold   = 3
    timeout             = 10
    matcher             = "200"
  }
}

resource "aws_lb_listener" "ingress" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "8080"
  #checkov:skip=CKV_AWS_2:using HTTP for demo to simplify deployment
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
  #checkov:skip=CKV_AWS_103:use HTTP only for demo purpose
}