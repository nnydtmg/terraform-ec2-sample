# terraform-ec2-sample
下記リソースを作成するTerraformコード
* 東京リージョンAZ-aにVPC・Subnet・EC2をパブリックに構築

以下のコマンドを実行してリソースを作成
```
terraform init

terraform plan
terraform apply
```

## セキュリティに関する注意

- 学習用のサンプルです。本番で利用する場合は、セキュリティグループの許可範囲などを要件に合わせて見直してください。
- EC2 インスタンスは IMDSv2 を必須にし、ルートボリュームを暗号化しています。
