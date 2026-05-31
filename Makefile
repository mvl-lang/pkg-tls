# pkg-tls -- TLS 1.3 client package
.PHONY: help check test assurance clean

.DEFAULT_GOAL := help

MVL ?= mvl
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

clean: ## Remove build artifacts
	rm -rf $(TMPDIR)mvl_build_tls
