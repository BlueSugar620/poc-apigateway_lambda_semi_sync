import os
import json

import boto3


# 環境変数の設定
SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"] 

def lambda_handler(event, context):

    # payload 受け取り
    try:
        request_id = event["request_id"]
        a = int(event["a"])
        b = int(event["b"])
    except Exception as e:
        print(f"Cannot get payload: {e}")
        return {
                "statusCode": 500,
            }
    print(f"Get payload\n request_id: {request_id}, a: {a}, b: {b}")

    # SQS にリクエストを送信する
    sqs_client = boto3.client("sqs")
    body = {
        "request_id": request_id,
        "a": a,
        "b": b,
    }
    try:
        response = sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(body),
            MessageGroupId="1",
        )
    except Exception as e:
        print(f"Cannot send message to SQS: {e}")
        return {
                "statusCode": 500,
            }
    
    return {
            "statusCode": 200,
        }
