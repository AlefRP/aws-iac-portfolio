# Terraform AWS Data Platform

Projeto Terraform profissional que provisiona uma **plataforma de dados na AWS** ponta-a-ponta: uma Lambda coleta cotacoes do Yahoo Finance, um job Glue (PySpark) transforma o dado bruto em Parquet particionado, dois crawlers populam o Glue Data Catalog, e o Athena consulta tudo via SQL.

## Arquitetura

```text
EventBridge (cron diario)
        |
        v
  Lambda Python  (stdlib only)         <- coleta tickers do Yahoo Finance
        |
        v
  S3 data bucket / raw/yahoo_finance/dt=YYYY-MM-DD/<ticker>.json
        |
        v
  Glue Crawler (raw)  -> Glue Catalog (raw_*)
        |
        v
  Glue Job PySpark  (stocks_etl)
        |
        v JSON -> Parquet partitionBy(ticker, year)
  S3 data bucket / curated/stocks/ticker=AAPL/year=2026/*.parquet
        |
        v
  Glue Crawler (curated) -> Glue Catalog (curated_*)
        |
        v
  Athena Workgroup -> SQL queries (resultados em S3)
```

## Estrutura do repositorio

```text
.
|-- provider.tf                 # Terraform + provider AWS
|-- variables.tf                # Variaveis do root
|-- main.tf                     # Composicao dos modulos
|-- outputs.tf                  # Outputs do root
|-- terraform.tfvars.example    # Exemplo de variaveis
|
|-- lambdas/
|   `-- yahoo_finance_collector/
|       `-- handler.py          # Codigo Python da Lambda (stdlib + boto3)
|
|-- glue_scripts/
|   `-- stocks_etl.py           # Script PySpark do Glue Job
|
|-- modules/
|   |-- s3_bucket/              # Bucket S3 seguro
|   |-- iam_user/               # Usuario IAM com policies
|   |-- lambda/                 # Funcao + role + EventBridge schedule
|   |-- glue_database/          # Glue Catalog database
|   |-- glue_crawler/           # Crawler com role e S3 access
|   |-- glue_job/               # Glue Job + script S3 + role
|   `-- athena_workgroup/       # Athena workgroup com cost guardrail
|
|-- tests/
|   `-- integration.tftest.hcl  # Teste de integracao do root
|
|-- examples/
|   `-- basic/                  # Exemplo basico s3_bucket + iam_user
|
|-- .github/workflows/terraform.yml   # CI: fmt, validate (matrix), tflint, test (matrix), trivy
|-- .tflint.hcl                       # Config TFLint
|-- .pre-commit-config.yaml           # Hooks pre-commit
|-- Makefile                          # Atalhos
`-- .gitignore
```

## Componentes provisionados

| Recurso | Modulo | Descricao |
| --- | --- | --- |
| 1x S3 bucket (data lake) | `s3_bucket` | versionamento, SSE-S3, public-block, lifecycle |
| 1x S3 bucket (Athena results) | `s3_bucket` | lifecycle 30d, sem versionamento |
| 1x Lambda Python 3.12 | `lambda` | EventBridge daily 06:00 UTC, IAM role minima |
| 1x Glue Catalog database | `glue_database` | nome `<project>_<env>` (snake_case) |
| 2x Glue Crawler | `glue_crawler` | raw e curated, prefixos diferentes |
| 1x Glue Job (PySpark 4.0) | `glue_job` | upload do script para S3, role com S3 RW |
| 1x Athena Workgroup | `athena_workgroup` | result location SSE-S3, byte cutoff 1GB |

## Pre-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6
- [AWS CLI](https://aws.amazon.com/cli/) configurada (`aws configure`)
- Opcional: TFLint, Trivy, pre-commit, make

## Como usar

```powershell
# 1. copie o arquivo de variaveis
Copy-Item terraform.tfvars.example terraform.tfvars

# 2. edite terraform.tfvars e troque os 2 nomes de bucket por nomes globalmente unicos

# 3. inicialize, planeje e aplique
terraform init
terraform plan
terraform apply
```

Pos-deploy (executar apos o `apply`):

```powershell
# invoca a Lambda manualmente (1a coleta)
aws lambda invoke --function-name $(terraform output -raw lambda_function_name) /tmp/out.json

# roda os crawlers
aws glue start-crawler --name $(terraform output -raw raw_crawler_name)

# executa o Glue Job
aws glue start-job-run --job-name $(terraform output -raw etl_job_name)

# roda o crawler curated
aws glue start-crawler --name $(terraform output -raw curated_crawler_name)

# consulta no Athena
aws athena start-query-execution \
  --query-string "SELECT ticker, date, close FROM curated_stocks WHERE year=2026 LIMIT 10" \
  --work-group $(terraform output -raw athena_workgroup_name)
```

Com `make`:

```bash
make help          # lista todos os alvos
make init          # init em root + todos os modulos + exemplo
make fmt           # formata
make validate      # valida tudo
make test          # testes do root
make test-modules  # testes de cada modulo
make test-all      # tudo
make lint          # tflint
make security      # trivy config
```

## Testes

Framework nativo `terraform test` com `mock_provider` -> roda **sem credenciais AWS** e **sem criar recursos reais**.

```bash
$ make test-all
# 6 root + 7 s3_bucket + 6 iam_user + 4 lambda + 2 glue_database
# + 3 glue_crawler + 3 glue_job + 3 athena_workgroup
# = 34 testes
```

Cobertura por modulo:

| Modulo | Cenarios testados |
| --- | --- |
| `s3_bucket` | baseline (block public, versioning, encryption), tags, KMS, lifecycle, validacao de nome |
| `iam_user` | criacao, tags, inline policies, managed policies, access key opcional |
| `lambda` | role, runtime/handler defaults, schedule opcional, env vars, extra policies |
| `glue_database` | nome, descricao |
| `glue_crawler` | role, multiple targets, table prefix |
| `glue_job` | role, defaults Glue 4.0, command glueetl, default arguments merge |
| `athena_workgroup` | enforce config, cost cutoff, SSE-S3, result location |
| root (integration) | composicao, paths consistentes, 2 buckets, validacao de env |

## Variaveis principais (root)

| Nome | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `aws_region` | string | `us-east-1` | Regiao AWS |
| `aws_profile` | string | `default` | Perfil AWS CLI |
| `environment` | string | `dev` | dev / staging / prod |
| `project_name` | string | `tf-data` | Prefixo de nomes |
| `data_bucket_name` | string | - | Nome unico do bucket de dados (obrigatorio) |
| `athena_results_bucket_name` | string | - | Nome unico do bucket de resultados Athena |
| `tickers` | list(string) | 7 tickers US+BR | Tickers Yahoo Finance |
| `yahoo_range` | string | `5d` | Range Yahoo (`5d`, `1mo`, `1y`, ...) |
| `yahoo_interval` | string | `1d` | Intervalo (`1d`, `1wk`) |
| `lambda_schedule` | string | `cron(0 6 * * ? *)` | EventBridge cron, null desabilita |

## Outputs principais

| Nome | Descricao |
| --- | --- |
| `data_bucket` | Nome do bucket data lake |
| `athena_results_bucket` | Nome do bucket de resultados |
| `raw_path` / `curated_path` | URIs S3 das zonas |
| `lambda_function_name` | Nome da Lambda |
| `glue_database_name` | Nome do database Glue |
| `raw_crawler_name` / `curated_crawler_name` | Nomes dos crawlers |
| `etl_job_name` | Nome do Glue Job |
| `athena_workgroup_name` | Nome do workgroup |

## Seguranca

- Bloqueio publico em todos os buckets (4 flags em `true`)
- Criptografia em repouso SSE-S3 (KMS opcional via `kms_key_arn`)
- Athena results com SSE-S3 + cost guardrail de 1 GB scan/query
- Roles IAM com **menor privilegio** (politicas inline scoped a recursos especificos)
- `force_destroy = false` no bucket de dados, `true` no de resultados (consumiveis)
- CI roda Trivy IaC scan e falha em HIGH/CRITICAL
- Sem secrets/keys hardcoded; auth via AWS CLI profile

## CI/CD

`.github/workflows/terraform.yml`:

1. `terraform fmt -check -recursive`
2. `terraform validate` em **matrix** (root + 7 modulos + exemplo)
3. `tflint --recursive`
4. `terraform test` em **matrix** (root + 7 modulos)
5. `trivy config` falhando em HIGH/CRITICAL

E uma esteira de **deploy real** ainda **nao** esta configurada. Pra isso seria necessario: backend remoto (S3 + DynamoDB), OIDC role no AWS para o GitHub, jobs `plan` (em PR) e `apply` (em `main` com `environment` protection).

## Licenca

MIT
