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

.PHONY: inventory
inventory: ## Generate ansible/inventory/hosts.ini from Terraform output
	./scripts/gen-inventory.sh

# SSH_KEY: path to the EC2 private key for Ansible.
# Set in .env (preferred) or pass on the command line: make bootstrap SSH_KEY=/path/to/key.pem
# If unset, Ansible falls back to private_key_file in ansible/ansible.cfg.
SSH_KEY ?=

.PHONY: bootstrap
bootstrap: ## Run Ansible bootstrap playbook (OS baseline: packages, timezone, NTP)
	cd ansible && ansible-playbook playbooks/bootstrap.yml \
		$(if $(SSH_KEY),--private-key $(SSH_KEY),)

.PHONY: lint-ansible
lint-ansible: ## Run ansible-lint on the Ansible directory
	cd ansible && ansible-lint .
