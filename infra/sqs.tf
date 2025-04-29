resource "aws_sqs_queue" "fifo" { 
  name = "${var.prefix}-sqs-queue.fifo"
  fifo_queue = true
  max_message_size = 2048
  content_based_deduplication = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter.arn
    maxReceiveCount = 4
  })
}

resource "aws_sqs_queue" "deadletter" { 
  name = "${var.prefix}-sqs-deadletter-queue.fifo"
  fifo_queue = true
  max_message_size = 2048
  content_based_deduplication = true
}

resource "aws_sqs_queue_redrive_allow_policy" "queue_redrive_allow_policy" { 
  queue_url = aws_sqs_queue.deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns = [aws_sqs_queue.fifo.arn]
  })
}
