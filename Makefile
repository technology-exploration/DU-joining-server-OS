LANG = en_US.UTF-8
SHELL := /bin/bash
.SHELLFLAGS := --norc --noprofile -e -u -o pipefail -c
.DEFAULT_GOAL := test

nvm_brew = /usr/local/opt/nvm/nvm.sh
ifneq ("$(wildcard $(nvm_brew))", "")
	nvm_sh = $(nvm_brew)
endif
nvm_default = $(HOME)/.nvm/nvm.sh
ifneq ("$(wildcard $(nvm_default))", "")
	nvm_sh = $(nvm_default)
endif
node_version = $(shell cat .nvmrc)
define npm
	@$(eval args=$(1))
	bash -e -o pipefail -l -c "source $(nvm_sh) && nvm exec $(node_version) npm $(args)"
endef
define node
	@$(eval args=$(1))
	bash -e -o pipefail -l -c "source $(nvm_sh) && nvm exec $(node_version) node $(args)"
endef

node_modules: ## Run 'npm ci' if directory doesn't exist
	$(call npm, ci)

.PHONY: npm-ci
npm-ci: node_modules ## Run npm ci

.PHONY: npm-install
npm-install: ## Run npm install
	$(call npm, install)

.PHONY: npm-publish
npm-publish: ## Run npm publish
	$(call npm, publish . --access private)

.PHONY: npm-pack
npm-pack: ## Run npm pack
	$(call npm, pack)

.PHONY: npm-test
npm-test: node_modules ## Run npm test
	$(call npm, test)

NODE_BIN:=$(shell pwd)/node_modules/.bin
.PHONY: eslint
eslint: ## Run eslint
	$(call node, $(NODE_BIN)/eslint --config .eslintrc.js --ext .js .)

.PHONY: eslint-fix
eslint-fix: ## Run eslint with fix options
	$(call node, $(NODE_BIN)/eslint --config .eslintrc.js --ext .js --fix .)

.PHONY: test
test: npm-test ## Run all tests


.PHONY: run
run: export PORT=8787
run: export NODE_ENV=development
run: export LOG_LEVEL=trace
run: export PRIVATE_KEY=PRIVATE_KEY
run: ## Run Data Union Join Server
	$(call node, src/cmd/duj-srv/main.js)

.PHONY: aws-src-bundle
ZIP:=/usr/bin/zip
FILE=$(PWD)/data-union-src-deploy-aws-$(shell date +"%F_%H.%M.%S").zip
IGNORED_FILES:=.git .DS_Store *.diff *.patch *.bash *.zip
FILES:=package.json package-lock.json src Procfile .ebextensions
aws-src-bundle:
	$(ZIP) -r $(FILE) $(FILES) -x $(IGNORED_FILES)

.PHONY: clean
clean: ## Remove generated files
	$(RM) -r \
		node_modules

.PHONY: clean-dist
clean-dist: clean ## Remove generated files and distributable files
	$(RM) -r \
		data-union-src-deploy-aws-*.zip

.PHONY: help
help: ## Show Help
	@grep -E '^[a-zA-Z0-9_\-\/]+%?:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}' | sort
