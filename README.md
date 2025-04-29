# poc-apigateway_lambda_semi_sync

API Gateway を使った、通常の同期 API と SQS を用いた半非同期 API のサンプルコードです。

## アーキテクチャ
![Image](https://github.com/user-attachments/assets/3877388b-510d-4266-bddf-f142f096cd6d)

## ディレクトリ構成

```
.
├─ app   
│   ├── get_helloworld          # GET /helloworld に対する Lambda コード    
│   │   └─ lambda_function.py
│   ├── post_plus               # POST /plus に対する Lambda コード
│   │   └─ lambda_function.py
│   ├── push_sqs                # post_plus から呼び出される SQS にメッセージを push する Lambda コード
│   │   └─ lambda_function.py
│   ├── calc_plus               # SQS からメッセージを受け取り、足し算を行う Lambda コード
│   │   └─ lambda_function.py
│   └─ openapi.yaml             # API 定義
│   
└─ infra
    ├─ apigateway.tf            # API Gatewayの定義 app/openapi.yaml から作成される。
    ├─ certificate.tf           # API Gateway のための証明書
    ├─ data.tf                  # 全体で使用するアカウント情報
    ├─ dynamodb.tf              # 半同期処理のためのデータベーステーブル定義
    ├─ lambda.tf                # 関数定義
    ├─ main.tf                  
    ├─ route53.tf               # API Gateway へのエイリアスレコードと証明書検証用の CNAME レコード
    ├─ sqs.tf                   # SQS 定義。デッドレターキューは未使用。
    └─ variables.tf             # 変数定義
```

## 使い方

### デプロイの方法

```
export TF_VAR_prefix=<プレフィックス名>
export TF_VAR_domain_name=<ドメイン名>

terraform init
terraform apply
```

### リクエストの送り方

```
$ curl https://<ドメイン名>/helloworld
{"message": "Hello World from API Gateway!"}

$ curl -X POST -H "Content-Type: application/json" -d '{"a": "3", "b": "5"}' https://<ドメイン名>/plus
{"a": 3, "b": 5, "c": 8}
```
