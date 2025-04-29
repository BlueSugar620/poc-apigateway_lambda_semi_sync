# ----------
# API Gateway 用の証明書
# ----------
resource "aws_acm_certificate" "api_gateway" { 
  domain_name = var.domain_name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "api_gateway" { 
  certificate_arn = aws_acm_certificate.api_gateway.arn
  validation_record_fqdns = [ for record in aws_route53_record.api_gateway_validation : record.fqdn ]
}
