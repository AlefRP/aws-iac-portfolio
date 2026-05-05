# Terraform AWS S3

Projeto Terraform profissional que provisiona um bucket S3 seguro e um usuario IAM de menor privilegio, organizado em modulos reutilizaveis com testes nativos e CI/CD.

## Arquitetura

```text
.
├── provider.tf                 # Terraform + provider AWS (com default_tags)
├── variables.tf                # Variaveis do root module
├── main.tf                     # Composicao dos modulos
├── outputs.tf                  # Outputs do root module
├── terraform.tfvars.example    # Exemplo de variaveis
├── texto.txt                   # Arquivo de exemplo enviado ao bucket
│
├── modules/
│   ├── s3_bucket/              # Modulo: bucket S3 seguro
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── README.md
│   │   └── tests/
│   │       └── s3_bucket.tftest.hcl
│   │
│   └── iam_user/               # Modulo: usuario IAM com policies
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── README.md
│       └── tests/
│           └── iam_user.tftest.hcl
│
├── tests/
│   └── integration.tftest.hcl  # Teste de integracao do root
│
├── examples/
│   └── basic/                  # Exemplo minimo de uso dos modulos
│
├── .github/workflows/
│   └── terraform.yml           # CI: fmt, validate, tflint, test, trivy
│
├── .tflint.hcl                 # Configuracao do TFLint
├── .pre-commit-config.yaml     # Hooks de pre-commit
├── Makefile                    # Atalhos para tarefas comuns
└── .gitignore
```

## Pre-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.0 (para `terraform test` e `mock_provider`)
- [AWS CLI](https://aws.amazon.com/cli/) configurada (`aws configure`)
- Opcional: [TFLint](https://github.com/terraform-linters/tflint), [trivy](https://github.com/aquasecurity/trivy), [pre-commit](https://pre-commit.com/), `make`

## Como usar

```powershell
# 1. copie o arquivo de variaveis
Copy-Item terraform.tfvars.example terraform.tfvars

# 2. edite terraform.tfvars e defina um bucket_name globalmente unico

# 3. inicialize, planeje e aplique
terraform init
terraform plan
terraform apply

# para destruir tudo
terraform destroy
```

Se voce tem `make` disponivel:

```powershell
make help          # lista todos os alvos
make init          # init em todos os modulos
make fmt           # formata o codigo
make validate      # valida sintaxe
make test          # roda terraform test do root
make test-modules  # roda terraform test em cada modulo
make lint          # roda tflint
make security      # roda trivy
```

## Recursos provisionados

| Recurso | Descricao |
| --- | --- |
| `aws_s3_bucket` | Bucket privado com tags |
| `aws_s3_bucket_public_access_block` | Bloqueio total de acesso publico |
| `aws_s3_bucket_versioning` | Versionamento habilitado |
| `aws_s3_bucket_server_side_encryption_configuration` | Criptografia AES256 (ou KMS opcional) |
| `aws_s3_bucket_lifecycle_configuration` | Expiracao de versoes antigas (90d) e multipart aborted (7d) |
| `aws_s3_object` | Upload de `texto.txt` |
| `aws_iam_user` | Usuario para acesso programatico |
| `aws_iam_user_policy` | Politica inline de menor privilegio (so o bucket criado) |

## Testes

O projeto usa o framework nativo `terraform test` com `mock_provider`, ou seja, **os testes rodam sem credenciais AWS e sem criar recursos reais**.

```powershell
# testes de integracao no root
terraform test

# testes de cada modulo
cd modules/s3_bucket
terraform test

cd ../iam_user
terraform test
```

Cobertura de testes:

- **`s3_bucket`**: baseline de seguranca (block public, versioning, encryption), tags, KMS opcional, lifecycle, validacao de nome
- **`iam_user`**: criacao basica, tags, multiplas inline policies, managed policies, access key opcional, validacoes
- **root**: composicao dos modulos, escopo de IAM (sem `s3:*`), propagacao de tags, validacao de `environment`

## Seguranca

| Pratica | Como |
| --- | --- |
| Bloqueio de acesso publico | `aws_s3_bucket_public_access_block` com 4 flags em `true` |
| Criptografia em repouso | SSE-S3 (AES256) por padrao, SSE-KMS quando `kms_key_arn` e fornecido |
| Versionamento | habilitado por padrao |
| Menor privilegio | politica IAM inline com acoes especificas e ARN do bucket |
| Sem credencial hardcoded | autenticacao via perfil AWS CLI / variaveis de ambiente |
| Lifecycle | versoes antigas expiram em 90d, multipart pendentes em 7d |
| `force_destroy = false` | bucket nao pode ser destruido com objetos |
| CI/CD | `trivy` e `tflint` rodam em cada PR |

## Variaveis (root)

| Nome | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `aws_region` | string | `"us-east-1"` | Regiao AWS |
| `aws_profile` | string | `"default"` | Perfil da AWS CLI |
| `environment` | string | `"dev"` | `dev`, `staging` ou `prod` |
| `bucket_name` | string | — | Nome unico do bucket S3 (obrigatorio) |
| `iam_user_name` | string | `"terraform-s3-user"` | Nome do usuario IAM |
| `tags` | map(string) | veja `variables.tf` | Tags aplicadas a todos os recursos |

## Outputs (root)

| Nome | Descricao |
| --- | --- |
| `bucket_id` | Nome do bucket |
| `bucket_arn` | ARN do bucket |
| `bucket_regional_domain_name` | Dominio regional |
| `bucket_region` | Regiao do bucket |
| `iam_user_arn` | ARN do usuario IAM |
| `iam_user_name` | Nome do usuario IAM |

## CI/CD

Workflow em `.github/workflows/terraform.yml` executa em cada push/PR:

1. `terraform fmt -check -recursive`
2. `terraform validate` em root + cada modulo + exemplo (matrix)
3. `tflint --recursive`
4. `terraform test` no root e em cada modulo
5. `trivy` para scan de seguranca

## Modulos

Cada modulo tem README proprio com inputs, outputs e exemplo de uso:

- [`modules/s3_bucket`](modules/s3_bucket/README.md)
- [`modules/iam_user`](modules/iam_user/README.md)

## Licenca

MIT
