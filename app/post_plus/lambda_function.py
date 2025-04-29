import os
import json
import time

import boto3


# 環境変数の設定
FUNCTION_ARN = os.environ.get("FUNCTION_ARN")
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME")


def lambda_handler(event, context):
    
    # body からパラメータを取得
    try:
        body = json.loads(event["body"])
        a = int(body["a"])
        b = int(body["b"])
        request_id = event["requestContext"]["requestId"]
    except Exception as e:
        print(f"Cannot get body parameters: {e}")
        return {
                "statusCode": 406,
            }
    print(f"Get parameters\na: {a} b: {b}\nrequestId: {request_id}")

    # 処理を Lambda に送る
    payload = {
        "request_id": request_id,
        "a": a,
        "b": b,
    }
    lambda_client = boto3.client("lambda")
    try:
        response = lambda_client.invoke(
            FunctionName=FUNCTION_ARN,
            InvocationType="RequestResponse",
            Payload=json.dumps(payload),
        )
        if response["StatusCode"] != 200:
            print(f"Process failed: statusCode: {response[statusCode]}")
            return {
                    "statusCode": 500,
                }
    except Exception as e:
        print(f"Cannot send a request to LAMBDA: {e}")
        return {
                "statusCode": 500,
            }
    print(f"Execute Lambda\nresponse: {response}")

    # DynamoDB をポーリングする
    print("Start polling")
    for i in range(10):
        print(f"{i + 1} time{"s" if i > 0 else ""}")
        dynamodb_client = boto3.client("dynamodb")
        response = dynamodb_client.get_item(
            TableName=DYNAMODB_TABLE_NAME,
            Key={
                "request_id": { "S": request_id },
            }
        )
        if len(response.get("Item", {})) > 0:
            break
        time.sleep(0.1)
    else:
        print(f"There is no item")
        return {
                "statusCode": 500,
            }
    item = response["Item"]
    print(f"Get result from dynamoDB\nitem: {item}")

    # 結果を返す
    body = {
        "a": a,
        "b": b,
        "c": int(item["result"]["N"]),
    }
    return {
            "statusCode": 200,
            "body": json.dumps(body),
        }
