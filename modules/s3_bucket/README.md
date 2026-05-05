# Module: s3_bucket

Cria um bucket S3 com configuracoes de seguranca por padrao:

- Bloqueio total de acesso publico
- Versionamento (configuravel, habilitado por padrao)
- Criptografia em repouso (SSE-S3 ou SSE-KMS quando `kms_key_arn` e fornecido)
- Bucket key habilitado para reduzir custos de KMS
- Regras de lifecycle opcionais

## Uso

```hcl
module "s3_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name = "meu-bucket-unico-2026"

  lifecycle_rules = [
    {
      id                                 = "expire-old-versions"
      noncurrent_version_expiration_days = 90
      abort_incomplete_multipart_days    = 7
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "demo"
  }
}
```

## Inputs

| Nome | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `bucket_name` | string | — | Nome unico do bucket |
| `force_destroy` | bool | `false` | Permite destruir bucket com objetos |
| `versioning_enabled` | bool | `true` | Habilita versionamento |
| `kms_key_arn` | string | `null` | ARN da chave KMS (usa AES256 se null) |
| `lifecycle_rules` | list(object) | `[]` | Regras de lifecycle |
| `tags` | map(string) | `{}` | Tags aplicadas ao bucket |

## Outputs

| Nome | Descricao |
| --- | --- |
| `bucket_id` | Nome do bucket |
| `bucket_arn` | ARN do bucket |
| `bucket_regional_domain_name` | Dominio regional |
| `bucket_region` | Regiao do bucket |
| `bucket_hosted_zone_id` | Hosted zone ID para Route 53 |
