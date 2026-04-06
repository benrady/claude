SHELL:=$(shell which bash)
CURL=$(shell which curl)
GIT_ROOT=$(shell git rev-parse --show-toplevel)
TOOLS_HOME=$(CURDIR)/.tools
TOOLS_BIN=$(TOOLS_HOME)/bin

ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help:
	@grep -hE '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(CURL):
	$(error 'curl' could not be found on the PATH. Please install curl)

UV_VERSION=0.9.22
UV_ARCH=$(shell uname -m | sed 's/arm64/aarch64-apple-darwin/g' | sed 's/x86_64/x86_64-unknown-linux-gnu/g')
UV_ROOT=$(TOOLS_HOME)/uv-$(UV_VERSION)
UV=$(UV_ROOT)/uv-$(UV_ARCH)/uv
$(UV): | $(CURL)
	echo "Installing uv $(UV_VERSION)"
	mkdir -p $(UV_ROOT)
	$(CURL) -Ls https://github.com/astral-sh/uv/releases/download/$(UV_VERSION)/uv-$(UV_ARCH).tar.gz | tar -xz -C $(UV_ROOT)

export VIRTUAL_ENV=$(TOOLS_HOME)/venv
PYTHON_DEPS=$(VIRTUAL_ENV)/.python-deps-installed
$(PYTHON_DEPS): | $(UV)
	echo "Installing tools environment with uv"
	$(UV) venv --clear $(VIRTUAL_ENV)
	$(UV) pip install 'pre-commit>=3.0.0'
	touch $@

PRE_COMMIT=$(VIRTUAL_ENV)/bin/pre-commit
$(PRE_COMMIT): | $(PYTHON_DEPS)

GIT_PRE_COMMIT=$(GIT_ROOT)/.git/hooks/pre-commit
$(GIT_PRE_COMMIT): $(PRE_COMMIT)
	$(PRE_COMMIT) install

.PHONY: hooks
hooks: $(GIT_PRE_COMMIT) ## Install pre-commit hooks

# Project virtual environment (separate from tools venv)
PROJECT_VENV=$(CURDIR)/.venv
PROJECT_DEPS=$(PROJECT_VENV)/.project-deps-installed
$(PROJECT_DEPS): pyproject.toml | $(UV)
	echo "Installing project environment with uv sync"
	$(UV) sync --all-groups --project $(CURDIR)
	touch $@

PYTEST=$(PROJECT_VENV)/bin/pytest
RUFF=$(PROJECT_VENV)/bin/ruff
TY=$(PROJECT_VENV)/bin/ty

.PHONY: install
install: hooks $(PROJECT_DEPS) ## Bootstrap project and tools virtual environments

.PHONY: test
test: hooks $(PROJECT_DEPS) ## Run tests with pytest
	$(PYTEST)

.PHONY: lint
lint: hooks $(PROJECT_DEPS) ## Check for linting errors with ruff
	$(RUFF) check .

.PHONY: format
format: hooks $(PROJECT_DEPS) ## Auto-format code with ruff
	$(RUFF) format .

.PHONY: clean
clean: ## Remove installed tools and project virtual environments
	[[ ! -d $(TOOLS_HOME) ]] || $(PRE_COMMIT) uninstall
	rm -rf $(TOOLS_HOME) $(PROJECT_VENV)

.PHONY: todo
todo: hooks ## Print a list of relevant TODOs in the code
	@echo "Remaining WIP:"
	git grep -n TODO | egrep -v '^Makefile.*:todo:' && exit 1 || exit 0

.PHONY: pre-commit
pre-commit: hooks ## Reformat code, stage changes, and run pre-commit checks
	$(PRE_COMMIT)
