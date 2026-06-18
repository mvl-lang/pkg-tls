# pkg-tls -- TLS 1.3 client package
.PHONY: help check test assurance coverage prove version clean

.DEFAULT_GOAL := help

MVL := $(shell command -v mvl 2>/dev/null || echo mvl)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: ## Type-check package source files
	$(MVL) check $(DIR)src/

test: ## Run unit tests
	$(MVL) test $(DIR)src/

assurance: ## Full assurance: check + tests + assurance report
	$(MVL) check $(DIR)src/
	$(MVL) test $(DIR)src/
	$(MVL) assurance $(DIR)src/ --verbose

coverage: guard-mvl ## Run tests with behavioral branch coverage report
	$(MVL) test $(DIR)src/ --coverage

prove: guard-mvl ## Per-call-site refinement proof breakdown (verbose)
	$(MVL) prove $(DIR)src/ --verbose

version: ## Show current package version from mvl.toml
	@grep '^version' mvl.toml | sed 's/version *= *"\(.*\)"/\1/'

clean: ## Remove build artifacts
	rm -rf $(TMPDIR)mvl_build_tls

guard-mvl:
	@command -v $(MVL) >/dev/null 2>&1 || { echo "mvl not found in PATH"; exit 1; }
