# Example: basic

Demonstracao minima de como combinar os modulos `s3_bucket` e `iam_user` para criar um bucket privado com um usuario IAM com acesso somente leitura.

## Como rodar

```powershell
terraform init
terraform plan
terraform apply
```

## O que e criado

- 1 bucket S3 com versionamento, criptografia AES256 e bloqueio publico
- 1 usuario IAM com politica inline restrita a leitura desse bucket
