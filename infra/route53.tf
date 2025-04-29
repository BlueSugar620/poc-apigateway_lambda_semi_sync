# ----------
# API Gateway への alias レコード 
# ----------
resource "aws_route53_record" "api_gateway" { 
  zone_id = data.aws_route53_zone.main.zone_id
  name = data.aws_route53_zone.main.name
  type = "A"

  alias {
    evaluate_target_health = true
    name = aws_api_gateway_domain_name.main.regional_domain_name
    zone_id = aws_api_gateway_domain_name.main.regional_zone_id
  }
}

# ----------
# API gateway 用の証明書検証用の CNAME レコード
# ----------
resource "aws_route53_record" "api_gateway_validation" { 
  for_each = {
    for dvo in aws_acm_certificate.api_gateway.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  type = each.value.type
  zone_id = data.aws_route53_zone.main.zone_id
  ttl = 60
}
