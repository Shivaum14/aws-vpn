# ── aws-vpn Makefile ──────────────────────────────────────────────────────────
#
# Targets are added as each component is implemented. What is here now reflects
# what currently exists in the repo.
#
# Usage:
#   make help     list all available targets with descriptions

TF_DIR := terraform/environments/dev

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Run pre-commit hooks across all files
	pre-commit run --all-files

# ── Terraform ─────────────────────────────────────────────────────────────────
# All Terraform commands target the dev environment. -chdir changes into the
# root module directory so you don't need to cd there manually.

.PHONY: tf-init
tf-init: ## Initialise Terraform (download providers, set up backend)
	terraform -chdir=$(TF_DIR) init

.PHONY: tf-plan
tf-plan: ## Show what Terraform would change (dry run, no AWS writes)
	terraform -chdir=$(TF_DIR) plan

.PHONY: tf-apply
tf-apply: ## Apply Terraform changes (creates/modifies AWS resources)
	terraform -chdir=$(TF_DIR) apply

.PHONY: tf-destroy
tf-destroy: ## Destroy all Terraform-managed AWS resources
	terraform -chdir=$(TF_DIR) destroy
