# Contributing

This document describes the development workflow and conventions for this repository. Sections are
expanded as each component is implemented.

## Prerequisites

See the stack table in [README.md](README.md) for the tools used. At minimum you need `pre-commit`
to work with the repo hygiene hooks.

```bash
brew install pre-commit   # or: pip install pre-commit
```

## Branch and PR conventions

- Branch naming: `feature/<short-topic>` or `fix/<short-topic>` — kebab-case, concise.
- One PR per logical change. Each PR should leave the repo in a valid, working state.
- Target `main`. No long-lived feature branches.
- PR titles follow [Conventional Commits](https://www.conventionalcommits.org/) format:
  `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`, `refactor: ...`

## Pre-commit hooks

```bash
pre-commit install          # install hooks into .git/hooks
pre-commit run --all-files  # run manually across all files
```

Hooks run automatically on every `git commit`. The current hooks cover file hygiene (trailing
whitespace, end-of-file newlines, YAML validity) and Python formatting via ruff. Additional
tool-specific hooks (Terraform fmt, ansible-lint) are added in later PRs.

## Linting

```bash
make lint   # runs pre-commit across all files
```

Tool-specific lint targets (`terraform fmt`, `ansible-lint`, `ruff`, `mypy`) are added to the
Makefile as each component is introduced.

## Security reminders

- Never commit `terraform.tfvars`, `*.key`, `*.conf` (other than `.example` files), `clients.json`,
  `peers.json`, or `ansible/inventory/hosts.ini`.
- The `.gitignore` covers all of the above — but review before committing if in doubt.
