resource "aws_dynamodb_table" "post_plus_result_table" { 
  name = "${var.prefix}-post-plus-result"
  write_capacity = 10
  read_capacity = 10
  hash_key = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }
}
