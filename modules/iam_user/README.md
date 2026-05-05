# Module: iam_user

Cria um usuario IAM com politicas inline e/ou gerenciadas, opcionalmente com chave de acesso programatico.

## Uso

```hcl
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [module.s3_bucket.bucket_arn, "${module.s3_bucket.bucket_arn}/*"]
  }
}

module "iam_user" {
  source = "../../modules/iam_user"

  user_name = "deploy-bot"

  inline_policies = {
    "s3-access" = data.aws_iam_policy_document.s3_access.json
  }

  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Nome | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `user_name` | string | — | Nome do usuario IAM |
| `path` | string | `"/"` | Path do usuario |
| `force_destroy` | bool | `false` | Permite remover usuario com chaves/perfis |
| `inline_policies` | map(string) | `{}` | Politicas inline (`nome => JSON`) |
| `managed_policy_arns` | list(string) | `[]` | ARNs de policies gerenciadas |
| `create_access_key` | bool | `false` | Cria chave de acesso programatico |
| `tags` | map(string) | `{}` | Tags do usuario |

## Outputs

| Nome | Descricao |
| --- | --- |
| `user_arn` | ARN do usuario |
| `user_name` | Nome do usuario |
| `user_id` | ID unico do usuario |
| `access_key_id` | Access key ID (se criada) |
| `access_key_secret` | Secret (sensitive, se criada) |
