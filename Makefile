.PHONY: apply dry-run lint syntax-check dump help

REPO_URL := https://github.com/mcircuit/Fedora-Playbook.git
PLAYBOOK  := setup.yml
USER_NAME := $(shell whoami)

help:
	@echo "Targets:"
	@echo "  apply         Run the playbook via ansible-pull (real execution)"
	@echo "  dry-run       Show what would change (does NOT modify the system)"
	@echo "  lint          Static analysis with ansible-lint"
	@echo "  syntax-check  Parse the playbook without executing"
	@echo "  dump          Dump current system state into lists/ and files/"

apply:
	ansible-playbook setup.yml -Kv

dry-run:
	ansible-pull -U $(REPO_URL) -C main $(PLAYBOOK) -Kv --check --diff

lint:
	ansible-lint $(PLAYBOOK)

syntax-check:
	ansible-playbook -i inventory $(PLAYBOOK) --syntax-check

dump:
	./dump-current-state.sh $(USER_NAME)