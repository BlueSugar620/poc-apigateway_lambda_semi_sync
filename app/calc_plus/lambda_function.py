import os
import json

import boto3

DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]

def lambda_handler(event, context):

    # SQS からメッセージを受け取る
    for record in event["Records"]:

        # body を受け取る
        body = json.loads(record["body"])
        request_id = body["request_id"]
        a = int(body["a"])
        b = int(body["b"])

        # 足し算をする
        c = a + b

        # dynamoDB に結果を格納する
        dynamodb_client = boto3.client("dynamodb")
        try:
            response = dynamodb_client.put_item(
                TableName=DYNAMODB_TABLE_NAME,
                Item={
                    "request_id": { "S": request_id },
                    "result": { "N": str(c) },
                }
            )
        except Exception as e:
            print(f"Cannot put result to dynamoDB: {e}")
            return {
                    "statusCode": 500,
                }
        print(f"Send result to dynamoDB")

    return {
            "statusCode": 200,
        }
