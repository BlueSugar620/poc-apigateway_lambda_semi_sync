# ----------
# API Gateway にアタッチする IAM Role
# ----------
resource "aws_iam_role" "api_gateway_role" { 
  name = "${var.prefix}-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_exec_lambda_policy_attachment" { 
  role = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

data "aws_iam_policy_document" "api_gateway_assume_policy" { 
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

# ----------
# API Gateway
# ----------
resource "aws_api_gateway_rest_api" "api" { 
  name = "${var.prefix}-api"
  body = templatefile("${path.module}/../app/openapi.yaml", {
    get_helloworld_uri = aws_lambda_function.get_helloworld.invoke_arn
    post_plus_uri = aws_lambda_function.post_plus.invoke_arn
    credentials = aws_iam_role.api_gateway_role.arn
  })

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  put_rest_api_mode = "merge"
}

resource "aws_api_gateway_deployment" "deploy" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" { 
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "example"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      "requestId": "$context.requestId",
      "ip": "$context.identity.sourceIp",
      "requestTime": "$context.requestTime",
      "httpMethod": "$context.httpMethod",
      "routeKey": "$context.routeKey",
      "status": "$context.status",
      "protocol": "$context.protocol",
      "responseLength": "$context.responseLength",
      "integrationError": "$context.integrationErrorMessage"
    })
  }
}

# ----------
# API Gateway のカスタムドメイン設定
# ----------
resource "aws_api_gateway_domain_name" "main" { 
  domain_name = var.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.api_gateway.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "main" { 
  api_id = aws_api_gateway_rest_api.api.id
  stage_name = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}

# ----------
# API Gateway モニタリング用の設定
# ----------

resource "aws_cloudwatch_log_group" "api_logs" { 
  name = "/aws/${var.prefix}-api"
}

resource "aws_api_gateway_account" "self" { 
  cloudwatch_role_arn = aws_iam_role.api_gateway_logs_role.arn
}

resource "aws_iam_role" "api_gateway_logs_role" { 
  name = "${var.prefix}-api-gateway-logs-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_logs_assume_policy.json
}

data "aws_iam_policy_document" "api_gateway_logs_assume_policy" { 
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "api_gateway_logs_policy_attachment" { 
  role = aws_iam_role.api_gateway_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
