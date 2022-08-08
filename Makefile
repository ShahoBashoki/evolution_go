.DEFAULT_GOAL := help
SHELL = /bin/bash

# GIT SPECIFICS

GIT_HOOKS = .git/hooks/commit-msg .git/hooks/pre-commit .git/hooks/pre-push .git/hooks/prepare-commit-msg

$(GIT_HOOKS): .git/hooks/%: .githooks/%

.githooks/%:
	touch $@

.git/hooks/%:
	cp $< $@

.PHONY: clean-git-configs
clean-git-configs: ## Clean Git Configs
	echo 'clean-git-configs'

.PHONY: add-git-configs
add-git-configs: clean-git-configs ## Add Git Configs
	git config --global branch.autosetuprebase always
	git config --global color.branch true
	git config --global color.diff true
	git config --global color.interactive true
	git config --global color.status true
	git config --global color.ui true
	git config --global commit.gpgsign true
	git config --global core.autocrlf input
	git config --global core.editor 'code --wait'
	git config --global diff.tool code
	git config --global difftool.code.cmd 'code --diff $$LOCAL $$REMOTE --wait'
	git config --global gpg.program gpg
	git config --global before.defaultbranch main
	git config --global log.date relative
	git config --global merge.tool code
	git config --global mergetool.code.cmd 'code --wait $$MERGED'
	git config --global pull.default current
	git config --global pull.rebase true
	git config --global push.autoSetupRemote true
	git config --global push.default current
	git config --global rebase.autostash true
	git config --global rerere.enabled true
	git config --global stash.showpatch true
	git config --global tag.gpgsign true

.PHONY: clean-git-hooks
clean-git-hooks: ## Clean Git Hooks
	rm -fr $(GIT_HOOKS)

.PHONY: add-git-hooks
add-git-hooks: clean-git-hooks $(GIT_HOOKS) ## Add Git Hooks

.PHONY: clean-git
clean-git: clean-git-configs clean-git-hooks ## Clean Git Configs & Hooks

.PHONY: add-git
add-git: add-git-configs add-git-hooks ## Add Git Configs & Hooks

.PHONY: help
help: ## Help
	@grep --extended-regexp '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-33s\033[0m %s\n", $$1, $$2 }'

GO := $(shell go env GOPATH)
PKG_LIST := ./...
PWD := $(shell pwd)

.PHONY: build
build: ## Build
	go build -o build/evolution

.PHONY: coverage
coverage: ## Coverage
	go tool cover -func=./profile/cover.out
	go tool cover -html=./profile/cover.out -o=./profile/cover.html

.PHONY: doc
doc: ## Documentation
	go doc -all .

.PHONY: errcheck
errcheck: ## Error Check
	go install github.com/kisielk/errcheck@latest
	$(GO)/bin/errcheck $(PKG_LIST)

.PHONY: fix
fix: ## Fix
	go fix $(PKG_LIST)

.PHONY: format
fmt: ## Format
	go fmt $(PKG_LIST)

.PHONY: golangci-lint
golangci-lint: ## Golang CI Lint
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GO)/bin/golangci-lint run $(PKG_LIST)

.PHONY: gosec
gosec: ## Go Sec
	go install github.com/securego/gosec/v2/cmd/gosec@latest
	$(GO)/bin/gosec $(PKG_LIST)

.PHONY: govet
govet: ## Go Vet
	go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@latest
	go vet -vettool=$(GO)/bin/shadow $(PKG_LIST)

.PHONY: reviewdog
reviewdog: ## Review Dog
	go install github.com/reviewdog/reviewdog/cmd/reviewdog@latest
	$(GO)/bin/reviewdog -conf=./.reviewdog.yml -fail-on-error=true -filter-mode=nofilter -reporter=local

.PHONY: revive
revive: ## Revive
	go install github.com/mgechev/revive@latest
	$(GO)/bin/revive -config=./.revive.toml \
		-exclude ./vendor/... \
		$(PKG_LIST)

.PHONY: staticcheck
staticcheck: ## Static Check
	go install honnef.co/go/tools/cmd/staticcheck@latest
	$(GO)/bin/staticcheck $(PKG_LIST)

.PHONY: swagger
swagger: ## Swagger
	./script/swagger-filebuilder.sh $(CI) $(OUTPUT_SWAGGER)

.PHONY: test
test: ## Test
	mkdir -p ./profile
	go test $(PKG_LIST) -covermode=set -coverprofile=./profile/cover.out

.PHONY: test-race
test-race: ## Test Race
	go test $(PKG_LIST) -covermode=atomic -race
