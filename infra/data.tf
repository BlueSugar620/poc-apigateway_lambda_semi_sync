data "aws_caller_identity" "self" {}

data "aws_route53_zone" "main" { 
  name = var.domain_name
}

