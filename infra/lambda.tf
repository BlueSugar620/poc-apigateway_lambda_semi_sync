# ----------
# IAM Policy
# ----------
data "aws_iam_policy_document" "lambda_assume_policy" { 
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "do_sqs" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sqs:*"]

    resources = [
      "${aws_sqs_queue.fifo.arn}",
      "${aws_sqs_queue.fifo.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "do_sqs" { 
  name = "${var.prefix}-do-sqs-policy"
  policy = data.aws_iam_policy_document.do_sqs.json
}

data "aws_iam_policy_document" "do_dynamodb" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["dynamodb:*"]

    resources = [
      "${aws_dynamodb_table.post_plus_result_table.arn}",
      "${aws_dynamodb_table.post_plus_result_table.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "do_dynamodb" { 
  name = "${var.prefix}-do-dynamodb-policy"
  policy = data.aws_iam_policy_document.do_dynamodb.json
}

# ----------
# get_helloworld Lambda にアタッチする IAM Role
# ----------
resource "aws_iam_role" "get_helloworld_lambda_role" { 
  name = "${var.prefix}-get-helloworld-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "get_helloworld_lambda_exec_policy_attachment" { 
  role = aws_iam_role.get_helloworld_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------
# GET /helloworld に対する Lambda
# ----------
data "archive_file" "get_helloworld_zip" { 
  type = "zip"
  source_dir = "${path.module}/../app/get_helloworld"
  output_path = "${path.module}/.lambda/get_helloworld/lambda_fucntion.zip"
}

resource "aws_lambda_function" "get_helloworld" { 
  filename = data.archive_file.get_helloworld_zip.output_path
  function_name = "${var.prefix}-get-helloworld"
  role = aws_iam_role.get_helloworld_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.get_helloworld_zip.output_base64sha256
}

resource "aws_lambda_permission" "get_helloworld_from_api_gateway" { 
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_helloworld.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

# ----------
# post_plus Lambda にアタッチする IAM Role
# ----------
resource "aws_iam_role" "post_plus_lambda_role" { 
  name = "${var.prefix}-post-plus-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "post_plus_lambda_exec_policy_attachment" { 
  role = aws_iam_role.post_plus_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "post_plus_lambda_do_dynamodb_policy_attachment" { 
  role = aws_iam_role.post_plus_lambda_role.name
  policy_arn = aws_iam_policy.do_dynamodb.arn
}

data "aws_iam_policy_document" "post_plus_exec_push_sqs_lambda_policy" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${aws_lambda_function.push_sqs.arn}",
      "${aws_lambda_function.push_sqs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "post_plus_exec_push_sqs_lambda_policy" { 
  name = "${var.prefix}-post-plus-exec-push-sqs-lambda-policy"
  policy = data.aws_iam_policy_document.post_plus_exec_push_sqs_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "post_plus_exec_push_sqs_lambda_policy_attachement" { 
  role = aws_iam_role.post_plus_lambda_role.name
  policy_arn = aws_iam_policy.post_plus_exec_push_sqs_lambda_policy.arn
}

# ----------
# POST /plus に対する Lambda
# ----------
data "archive_file" "post_plus" { 
  type = "zip"
  source_dir = "${path.module}/../app/post_plus"
  output_path = "${path.module}/.lambda/post_plus/lambda_function.zip"
}

resource "aws_lambda_function" "post_plus" { 
  filename = data.archive_file.post_plus.output_path
  function_name = "${var.prefix}-post-plus"
  role = aws_iam_role.post_plus_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.post_plus.output_base64sha256

  timeout = 60

  environment {
    variables = {
      FUNCTION_ARN = aws_lambda_function.push_sqs.arn
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.post_plus_result_table.name
    }
  }
}

resource "aws_lambda_permission" "post_plus" { 
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_plus.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

# ----------
# push_sqs Lambda にアタッチする IAM Role
# ----------
resource "aws_iam_role" "push_sqs_lambda_role" { 
  name = "${var.prefix}-push-sqs-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "push_sqs_lambda_exec_policy_attachment" { 
  role = aws_iam_role.push_sqs_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "push_sqs_lambda_do_sqs" { 
  role = aws_iam_role.push_sqs_lambda_role.name
  policy_arn = aws_iam_policy.do_sqs.arn
}

# ----------
# post_plus の Lambda から呼び出される lambda
# ----------
data "archive_file" "push_sqs" { 
  type = "zip"
  source_dir = "${path.module}/../app/push_sqs"
  output_path = "${path.module}/.lambda/push_sqs/lambda_function.zip"
}

resource "aws_lambda_function" "push_sqs" { 
  filename = data.archive_file.push_sqs.output_path
  function_name = "${var.prefix}-push-sqs"
  role = aws_iam_role.push_sqs_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.push_sqs.output_base64sha256

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.fifo.url
    }
  }
}

# ----------
# calc_plus Lambda にアタッチする IAM Role
# ----------
resource "aws_iam_role" "calc_plus_lambda_role" { 
  name = "${var.prefix}-calc-plus-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "calc_plus_lambda_exec_policy_attachment" { 
  role = aws_iam_role.calc_plus_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "calc_plus_lambda_do_sqs_policy_attachment" { 
  role = aws_iam_role.calc_plus_lambda_role.name
  policy_arn = aws_iam_policy.do_sqs.arn
}

resource "aws_iam_role_policy_attachment" "calc_plus_lambda_do_dynamodb_policy_attachment" { 
  role = aws_iam_role.calc_plus_lambda_role.name
  policy_arn = aws_iam_policy.do_dynamodb.arn
}

# ----------
# SQS をトリガーする Lambda
# ----------
data "archive_file" "calc_plus" { 
  type = "zip"
  source_dir = "${path.module}/../app/calc_plus"
  output_path = "${path.module}/.lambda/calc_plus/lambda_function.zip"
}

resource "aws_lambda_function" "calc_plus" { 
  filename = data.archive_file.calc_plus.output_path
  function_name = "${var.prefix}-calc-plus"
  role = aws_iam_role.calc_plus_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.calc_plus.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.post_plus_result_table.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" { 
  event_source_arn = aws_sqs_queue.fifo.arn
  function_name = aws_lambda_function.calc_plus.arn
}
