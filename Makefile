# ── aws-vpn Makefile ──────────────────────────────────────────────────────────
#
# This Makefile is the primary operator interface for the project. Targets are
# added incrementally as features are implemented — see CONTRIBUTING.md for the
# full workflow. Targets here reflect what currently exists in the repo.
#
# Usage:
#   make help     list all available targets with descriptions

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Linting and formatting ────────────────────────────────────────────────────
# New tool-specific lint/fmt sub-targets are added here as each component is
# introduced (Terraform in PR 2, Ansible in PR 4, Python in PR 7).

.PHONY: lint
lint: ## Run all available linters (pre-commit hooks across all files)
	pre-commit run --all-files

.PHONY: fmt
fmt: ## Auto-format all code (tool-specific formatters added with each component)
	@echo "No formatters configured yet — sub-targets added with each component (PR 2+)"
