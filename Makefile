# Makefile for preregistration system
# ----------------------------------
# Provides commands to create/update prereg repos, verify integrity,
# and perform strict checks without auto-repair.

SHELL := /bin/bash

.PHONY: all new verify strict-verify clean help

# Default target: run verification
all: verify

# Create or update prereg repos and ledger
new:
	@echo "[INFO] Running preregistration (new)..."
	@if ! ./prereg-init.sh new; then \
		echo "[ERROR] prereg-init.sh new failed"; \
		exit 1; \
	fi

# Verify repos, hashes, and prereg index (auto-repair enabled)
verify:
	@echo "[INFO] Running verification (with auto-repair if needed)..."
	@if ! ./prereg-init.sh verify; then \
		echo "[ERROR] Verification failed — see log above"; \
		exit 1; \
	fi

# Verify repos, hashes, and prereg index (strict: no auto-repair)
strict-verify:
	@echo "[INFO] Running strict verification (no auto-repair)..."
	@if ! ./prereg-init.sh verify --strict; then \
		echo "[ERROR] Strict verification failed — see log above"; \
		exit 1; \
	fi

# Remove local repo directories (safe cleanup)
clean:
	@echo "[INFO] Cleaning up local repositories..."
	@for dir in */ ; do \
		if [ -d "$$dir/.git" ]; then \
			echo "Removing $$dir"; \
			rm -rf "$$dir"; \
		fi \
	done

# Print available targets
help:
	@echo "Preregistration Makefile"
	@echo
	@echo "Targets:"
	@echo "  new            Create or update prereg repos and ledger"
	@echo "  verify         Verify integrity (auto-repair claim-index.md if needed, then fail)"
	@echo "  strict-verify  Verify integrity without auto-repair (fail only)"
	@echo "  clean          Remove local cloned repositories"
	@echo "  help           Show this help message"
	@echo
	@echo "Default target: verify"

