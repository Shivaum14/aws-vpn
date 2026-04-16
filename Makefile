# ── aws-vpn Makefile ──────────────────────────────────────────────────────────
#
# Targets are added as each component is implemented. What is here now reflects
# what currently exists in the repo.
#
# Usage:
#   make help     list all available targets with descriptions

TF_DIR := terraform/environments/dev

# Load local variable overrides from .env if it exists.
# Copy .env.example to .env and fill in your values. .env is gitignored.
-include .env

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

# ── Ansible ───────────────────────────────────────────────────────────────────
# Ansible commands are run from the ansible/ directory so that ansible.cfg is
# automatically picked up (Ansible searches for ansible.cfg in the current
# working directory first).
#
# SSH_KEY_PATH must be set in .env before running any Ansible target.
# See .env.example for the required format.

.PHONY: _require-ssh-key-path
_require-ssh-key-path:
	@test -n "$(SSH_KEY_PATH)" || \
		(echo "ERROR: SSH_KEY_PATH is not set. Add it to .env (see .env.example)."; exit 1)

.PHONY: inventory
inventory: ## Generate ansible/inventory/hosts.ini from Terraform output
	./scripts/gen-inventory.sh

.PHONY: bootstrap
bootstrap: _require-ssh-key-path ## Run Ansible bootstrap playbook (OS baseline: packages, timezone, NTP)
	cd ansible && ansible-playbook playbooks/bootstrap.yml --private-key $(SSH_KEY_PATH)

.PHONY: lint-ansible
lint-ansible: ## Run ansible-lint on the Ansible directory
	cd ansible && ansible-lint .
