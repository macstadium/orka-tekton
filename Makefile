SHELL := /usr/bin/env bash -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables

-include .env
export

NAMESPACE ?= default
ORKA_API ?= http://10.221.188.20

.PHONY: help
help:
	@echo 'Usage:'
	@echo -e "\tmake <target>"
	@echo -e "\nTargets:\n"
	@echo -e "\tall:\t\tDefault target, same as 'make add-orka-creds add-ssh-creds install'"
	@echo -e "\tadd-orka-creds:\tCreates secret 'orka-creds', env vars EMAIL and PASSWORD must be set"
	@echo -e "\tadd-ssh-creds:\tCreates secret 'orka-ssh-creds', env vars SSH_USERNAME and SSH_PASSWORD must be set"
	@echo -e "\tinstall:\tRuns 'kubectl apply' on all tasks and creates 'orka-tekton-config' config map, ORKA_API env var may be set"
	@echo -e "\tclean:\t\tRemoves all tasks, secrets and config maps"

.PHONY: all install clean
all: add-orka-creds add-ssh-creds install

install:
	@sed -e 's|$$(url)|'"$(ORKA_API)"'|' resources/orka-tekton-config.yaml.tmpl | kubectl apply -f -
	@kubectl apply -f tasks

clean:
	@kubectl delete -f tasks --ignore-not-found
	@find resources -name "*.tmpl" -exec sed -e 's|$$(namespace)|'"$(NAMESPACE)"'|' {} \; | kubectl delete --ignore-not-found -f -

.PHONY: add-orka-creds
add-orka-creds:
	@sed -e 's|$$(email)|'"$(EMAIL)"'|' -e 's|$$(password)|'"$(PASSWORD)"'|' resources/orka-creds.yaml.tmpl | kubectl apply -f -

.PHONY: add-ssh-creds
add-ssh-creds:
	@sed -e 's|$$(username)|'"$(SSH_USERNAME)"'|' -e 's|$$(password)|'"$(SSH_PASSWORD)"'|' resources/orka-ssh-creds.yaml.tmpl | kubectl apply -f -

.PHONY: add-creds
add-creds: add-orka-creds add-ssh-creds
