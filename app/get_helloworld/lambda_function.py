import json

def lambda_handler(event, content):
    return {
            "statusCode": 200,
            "body": json.dumps({ "message": "Hello World from API Gateway!" }),
        }
