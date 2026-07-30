# ============================================================================
# EMPOWERPLANT MAKEFILE
# ============================================================================
# This Makefile provides automation for building, testing, and developing
# the EmpowerPlant app. Run 'make help' to see all available commands.
# ============================================================================

.DEFAULT_GOAL := help

# ============================================================================
# SETUP
# ============================================================================

## Setup the project by installing dependencies and pre-commit hooks.
#
# Sets up a fresh machine for development by chaining the install tasks.
# Safe to re-run if you need to reinitialize dependencies or hooks.
.PHONY: setup
setup: install-dependencies install-pre-commit

## Install the project dependencies using Homebrew.
#
# Installs all tools declared in the Brewfile and initializes git submodules.
.PHONY: install-dependencies
install-dependencies:
	brew bundle

## Install the pre-commit hooks.
#
# Installs repository git hooks to enforce formatting and checks before commits.
.PHONY: install-pre-commit
install-pre-commit:
	pre-commit install

# ============================================================================
# BUILDING
# ============================================================================

# Simulator OS version (defaults to 'latest', can be overridden via SIMULATOR_OS=18)
SIMULATOR_OS ?= latest

# Simulator device name (defaults to 'iPhone 17 Pro', can be overridden via DEVICE_NAME=iPhone 16 Pro)
DEVICE_NAME ?= iPhone 17 Pro

## Build all targets (iOS)
#
# Convenience target that invokes all iOS build targets.
# See build-ios for more details.
.PHONY: build
build: build-ios

## Build all iOS targets for simulator
#
# Builds the main app, the core framework, and the share extension for the latest simulator.
# See build-ios-app for more details.
.PHONY: build-ios
build-ios: build-ios-app

## Build App target for latest iOS Simulator (iPhone 17 Pro)
#
# Builds the main app for the latest iOS Simulator (iPhone 17 Pro).
# Outputs raw logs to raw-build-ios-app.log and pretty-prints with xcbeautify.
.PHONY: build-ios-app
build-ios-app: 
	set -o pipefail && NSUnbufferedIO=YES xcrun xcodebuild \
		-project EmpowerPlant.xcodeproj \
		-scheme EmpowerPlant \
		-destination 'platform=iOS Simulator,OS=$(SIMULATOR_OS),name=$(DEVICE_NAME)' \
		build | tee raw-build-ios-app.log | xcbeautify --preserve-unbeautified

# ============================================================================
# TESTING
# ============================================================================

# Optional: ONLY_TESTING=Target/ClassName or Target/ClassName/testMethodName to run specific tests
# Examples:
#   make test-ios-app ONLY_TESTING=AppTests/SomeTestClass
#   make test-ui ONLY_TESTING=UITests/UITests/testFeedbackButtonExistsOnListsView
ONLY_TESTING ?=

## Run all test suites
#
# Runs all tests for all primary targets.
.PHONY: test
test: test-ios

## Run all iOS tests
#
# Runs all unit tests for all primary iOS targets.
.PHONY: test-ios
test-ios: test-ios-app

## Run unit tests for App scheme on latest iOS Simulator
#
# Runs unit tests for the App scheme on the latest iOS Simulator (iPhone 17 Pro).
# Writes logs to raw-test-ios-app.log and formats output with xcbeautify.
#
# Optional: ONLY_TESTING=Target/ClassName to run specific test class(es)
# Examples:
#   make test-ios-app
#   make test-ios-app ONLY_TESTING=AppTests/SomeTestClass
.PHONY: test-ios-app
test-ios-app:
	set -o pipefail && NSUnbufferedIO=YES xcrun xcodebuild \
		-project EmpowerPlant.xcodeproj \
		-scheme EmpowerPlant \
		-destination 'platform=iOS Simulator,OS=$(SIMULATOR_OS),name=$(DEVICE_NAME)' $(if $(ONLY_TESTING),-only-testing:$(ONLY_TESTING)) \
		test | tee raw-test-ios-app.log | xcbeautify --preserve-unbeautified
	slather coverage --configuration Test --verbose

# ============================================================================
# FORMATTING
# ============================================================================

## Format Swift, Markdown, JSON and YAML files using project tools
#
# Runs all formatting tasks for all Swift, JSON, Markdown, and YAML files in the project.
.PHONY: format
format: format-swift format-json format-markdown format-yaml

## Format Swift sources and apply SwiftLint auto-fixes
#
# Runs swift-format and SwiftLint to format and autofix Swift code.
.PHONY: format-swift
format-swift:
	swift format --configuration .swift-format.json --in-place --recursive .
	swiftlint --config .swiftlint.yml --strict --fix

## Format all JSON files with dprint
#
# Runs dprint to format all JSON files.
.PHONY: format-json
format-json:
	dprint fmt "**/*.json"

## Format all Markdown files with dprint
#
# Runs dprint to format all Markdown files.
.PHONY: format-markdown
format-markdown:
	dprint fmt "**/*.md"

## Format all YAML files with dprint
#
# Runs dprint to format all YAML and YML files.
.PHONY: format-yaml
format-yaml:
	dprint fmt "**/*.{yaml,yml}"

## Run SwiftLint and dprint checks (no fixes)
#
# Runs SwiftLint and dprint checks without modifying files.
.PHONY: lint
lint:
	swiftlint --config .swiftlint.yml --strict
	dprint check "**/*.{md,json,yaml,yml}"

# ============================================================================
# HELP & DOCUMENTATION
# ============================================================================

# Reusable awk script for detailed help output
define HELP_DETAIL_AWK
BEGIN { summary = ""; detailsCount = 0; printed = 0; lookingForDeps = 0 } \
/^## / { summary = substr($$0, 4); delete details; detailsCount = 0; next } \
/^#($$| )/ { \
	if (summary != "") { \
		line = $$0; \
		if (substr(line,1,2)=="# ") detailLine = substr(line,3); else detailLine = ""; \
		details[detailsCount++] = detailLine; \
	} \
	if (lookingForDeps && $$0 !~ /^#/) { lookingForDeps = 0 } \
	next \
} \
/^\.PHONY: / && summary != "" { \
	for (i = 2; i <= NF; i++) { \
		if ($$i == T) { \
			found = 1; \
			lookingForDeps = 1; \
			break \
		} \
	} \
	if (!found) { summary = ""; detailsCount = 0; delete details } \
	next \
} \
lookingForDeps && /^[A-Za-z0-9_.-]+[ \t]*:/ && $$0 !~ /^\.PHONY:/ && $$0 !~ /^\t/ && index($$0,"=")==0 { \
	raw = $$0; \
	split(raw, parts, ":"); \
	tn = parts[1]; \
	if (tn == T) { \
		depStr = substr(raw, index(raw, ":")+1); \
		gsub(/^[ \t]+|[ \t]+$$/, "", depStr); \
		firstDep = depStr; \
		split(depStr, depParts, /[ \t]+/); \
		if (length(depParts[1]) > 0) firstDep = depParts[1]; \
		lookingForDeps = 0; \
	} \
	next \
} \
found && !lookingForDeps { \
	printf "%s\n\n", summary; \
	for (j = 0; j < detailsCount; j++) { \
		if (length(details[j]) > 0) printf "%s\n", details[j]; else print ""; \
	} \
	print ""; \
	printf "Usage:\n"; \
	if (length(firstDep) > 0) { \
		printf "  make %s\n", firstDep; \
	} else { \
		printf "  make %s\n", T; \
	} \
	printed = 1; \
	found = 0; summary = ""; detailsCount = 0; delete details; firstDep = ""; \
	next \
} \
END { if (!printed) { printf "No detailed help found for target: %s\n", T } }
endef

## Show this help message with all available commands
#
# Displays a formatted list of all available make targets with descriptions.
# Commands are organized by topic for easy navigation.
.PHONY: help
help:
	@if [ -n "$(name)" ]; then \
		$(MAKE) --no-print-directory help-target name="$(name)"; \
	else \
		echo "=============================================="; \
		echo "🚀 EMPOWERPLANT DEVELOPMENT COMMANDS"; \
		echo "=============================================="; \
		echo ""; \
		awk 'BEGIN { summary = ""; n = 0; maxlen = 0 } \
		/^## / { summary = substr($$0, 4); delete details; detailsCount = 0; next } \
		/^\.PHONY: / && summary != "" { \
			for (i = 2; i <= NF; i++) { \
				targets[n] = $$i; \
				summaries[n] = summary; \
				if (length($$i) > maxlen) maxlen = length($$i); \
				n++; \
			} \
			summary = ""; next \
		} \
		END { \
			for (i = 0; i < n; i++) { \
				printf "\033[36m%-*s\033[0m %s\n", maxlen, targets[i], summaries[i]; \
			} \
		}' $(MAKEFILE_LIST); \
		echo ""; \
		echo "💡 Use 'make <command>' to run any command above."; \
		echo "📖 For detailed help on a command, run: make help-<command>  (e.g., make help-build-ios)"; \
		echo "📖 Or: make help name=<command>      (e.g., make help name=build-ios)"; \
		echo ""; \
	fi
 
.PHONY: help-% help-target
help-%:
	@target="$*"; \
	awk -v T="$$target" '$(HELP_DETAIL_AWK)' $(MAKEFILE_LIST)

help-target:
	@[ -n "$(name)" ] || { echo "Usage: make help name=<target>"; exit 1; }; \
	awk -v T="$(name)" '$(HELP_DETAIL_AWK)' $(MAKEFILE_LIST)
