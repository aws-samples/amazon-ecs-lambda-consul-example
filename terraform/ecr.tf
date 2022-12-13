resource "aws_ecr_repository" "greeting" {
  name         = "greeting"
  force_delete = true

  #checkov:skip=CKV_AWS_51:allow mutable tags for demo  
  #checkov:skip=CKV_AWS_163:disable image scanning for demo purpose
  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "name" {
  name         = "name"
  force_delete = true

  #checkov:skip=CKV_AWS_51:allow mutable tags for demo
  #checkov:skip=CKV_AWS_163:disable image scanning for demo purpose
  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "greeter" {
  name         = "greeter"
  force_delete = true

  #checkov:skip=CKV_AWS_51:allow mutable tags for demo
  #checkov:skip=CKV_AWS_163:disable image scanning for demo purpose
  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "ingress" {
  name         = "ingress"
  force_delete = true

  #checkov:skip=CKV_AWS_51:allow mutable tags for demo
  #checkov:skip=CKV_AWS_163:disable image scanning for demo purpose
  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "consul_lambda_registrator" {
  name         = "consul-lambda-registrator"
  force_delete = true

  #checkov:skip=CKV_AWS_51:allow mutable tags for demo
  #checkov:skip=CKV_AWS_163:disable image scanning for demo purpose
  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}