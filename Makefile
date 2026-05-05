.PHONY: help init fmt fmt-check validate lint test test-modules security plan apply destroy clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## terraform init em todos os modulos
	terraform init
	cd modules/s3_bucket && terraform init -backend=false
	cd modules/iam_user && terraform init -backend=false
	cd examples/basic && terraform init -backend=false

fmt: ## terraform fmt recursivo
	terraform fmt -recursive

fmt-check: ## verifica formatacao
	terraform fmt -check -recursive -diff

validate: ## terraform validate em todos os modulos
	terraform validate
	cd modules/s3_bucket && terraform validate
	cd modules/iam_user && terraform validate
	cd examples/basic && terraform validate

lint: ## roda tflint recursivo
	tflint --init
	tflint --recursive --format=compact

test: ## roda terraform test no root
	terraform test

test-modules: ## roda terraform test em todos os modulos
	cd modules/s3_bucket && terraform test
	cd modules/iam_user && terraform test

security: ## scan de seguranca com trivy
	trivy config .

plan: ## terraform plan
	terraform plan

apply: ## terraform apply
	terraform apply

destroy: ## terraform destroy
	terraform destroy

clean: ## limpa diretorios .terraform
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfstate*" -not -path "*/node_modules/*" -delete 2>/dev/null || true
