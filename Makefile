SHELL := /usr/bin/env bash -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables

-include .env
export

NAMESPACE ?= default
ORKA_API ?= http://10.221.188.20

.PHONY: help
help:
	@echo "Usage:"
	@echo -e "\tmake <target> [flags...]"
	@echo -e "\nTargets:"
	@echo -e "\tall:\tAdd secrets, config maps and install all tasks. Same as 'make add-orka-tekton-config add-creds install'"
	@echo -e "\tclean:\tRemove all tasks, secrets and config maps"
	@echo -e "\tbuild:\tBuild Docker image"
	@echo -e "\tpush:\tPush Docker image to repository"

.PHONY: all install clean
all: add-orka-tekton-config add-creds install

install:
	@kubectl apply -f tasks

clean:
	@kubectl delete -f tasks --ignore-not-found
	@find resources -name "*.tmpl" -exec sed -e 's|$$(namespace)|'"$(NAMESPACE)"'|' {} \; | kubectl delete --ignore-not-found -f -

.PHONY: add-orka-tekton-config
add-orka-tekton-config:
	@sed -e 's|$$(url)|'"$(ORKA_API)"'|' resources/orka-tekton-config.yaml.tmpl | kubectl apply -f -

.PHONY: add-orka-creds
add-orka-creds:
	@sed -e 's|$$(email)|'"$(EMAIL)"'|' -e 's|$$(password)|'"$(PASSWORD)"'|' resources/orka-creds.yaml.tmpl | kubectl apply -f -

.PHONY: add-ssh-creds
add-ssh-creds:
	@sed -e 's|$$(username)|'"$(SSH_USERNAME)"'|' -e 's|$$(password)|'"$(SSH_PASSWORD)"'|' resources/orka-ssh-creds.yaml.tmpl | kubectl apply -f -

.PHONY: add-creds
add-creds: add-orka-creds add-ssh-creds

.PHONY: build push
build:
	@docker build --tag $(IMAGE_REPO):$(IMAGE_TAG) .

push: build
	@docker push $(IMAGE_REPO):$(IMAGE_TAG)
