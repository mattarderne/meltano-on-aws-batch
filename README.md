# meltano-batch
Running Meltano ELT on AWS Batch, configured with terraform

Requires `terraform/secrets.tfvars` file

db_username = "meltano"
db_password = "<Make a DB password>"
aws_account = "<AWS ACCOUNT>"
access_ip_list = [
"0.0.0.0/0",
]

```
git clone git@github.com:mattarderne/meltano-batch.git
cd meltano-batch/terraform
vi secrets.tfvars
terraform init
```
Run with
```
terraform plan -var-file="secret.tfvars"
terraform apply -var-file="secret.tfvars"
```


