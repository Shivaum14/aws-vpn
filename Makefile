# ── aws-vpn Makefile ──────────────────────────────────────────────────────────
#
# Targets are added as each component is implemented. What is here now reflects
# what currently exists in the repo.
#
# Usage:
#   make help     list all available targets with descriptions

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Run pre-commit hooks across all files
	pre-commit run --all-files
