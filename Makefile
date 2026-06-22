SHELL:=$(shell which bash)
CURL=$(shell which curl)
GIT_ROOT=$(shell git rev-parse --show-toplevel)
TOOLS_HOME=$(CURDIR)/.tools

ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help:
	@grep -hE '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(CURL):
	$(error 'curl' could not be found on the PATH. Please install curl)

UV_VERSION=0.9.22
# Build the uv release target triple from OS and CPU independently, so this works
# on Linux and macOS, x86_64 and arm64 (uname -m reports aarch64 on Linux, arm64
# on macOS).
UV_CPU=$(shell uname -m | sed 's/arm64/aarch64/')
UV_OS=$(shell uname -s | sed 's/Darwin/apple-darwin/;s/Linux/unknown-linux-gnu/')
UV_ARCH=$(UV_CPU)-$(UV_OS)
UV_ROOT=$(TOOLS_HOME)/uv-$(UV_VERSION)
UV=$(UV_ROOT)/uv-$(UV_ARCH)/uv
$(UV): | $(CURL)
	echo "Installing uv $(UV_VERSION)"
	mkdir -p $(UV_ROOT)
	$(CURL) -Ls https://github.com/astral-sh/uv/releases/download/$(UV_VERSION)/uv-$(UV_ARCH).tar.gz | tar -xz -C $(UV_ROOT)

export VIRTUAL_ENV=$(TOOLS_HOME)/venv
PYTHON_DEPS=$(VIRTUAL_ENV)/.python-deps-installed
$(PYTHON_DEPS): | $(UV)
	echo "Installing Python Environment with uv"
	$(UV) venv --clear $(VIRTUAL_ENV)
	$(UV) pip install 'pre-commit>=3.0.0'
	touch $@

PRE_COMMIT=$(VIRTUAL_ENV)/bin/pre-commit
$(PRE_COMMIT): | $(PYTHON_DEPS)

GIT_PRE_COMMIT=$(GIT_ROOT)/.git/hooks/pre-commit
$(GIT_PRE_COMMIT): $(PRE_COMMIT)
	$(PRE_COMMIT) install

.PHONY: hooks
hooks: $(GIT_PRE_COMMIT) # Install pre-commit hooks

.PHONY: bootstrap
bootstrap: ## Symlink CLAUDE.md into ~/.claude
	mkdir -p $(HOME)/.claude
	ln -sf $(CURDIR)/CLAUDE.md $(HOME)/.claude/CLAUDE.md

.PHONY: pre-commit
pre-commit: hooks ## Run pre-commit checks against all files
	$(PRE_COMMIT) run --all-files

.PHONY: clean
clean: ## Remove installed tools
	[[ ! -d $(TOOLS_HOME) ]] || $(PRE_COMMIT) uninstall
	rm -rf $(TOOLS_HOME)
