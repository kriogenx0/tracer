PROJECT := Tracer.xcodeproj
SCHEME := TracerApp
APP_NAME := Tracer
BUILD_DIR := build
DEBUG_APP := $(BUILD_DIR)/Debug/$(APP_NAME).app
RELEASE_APP := $(BUILD_DIR)/Release/$(APP_NAME).app
INSTALL_APP := /Applications/$(APP_NAME).app

.DEFAULT_GOAL := all
.PHONY: all setup generate dev build clean open close install uninstall reinstall install-open help

##@ Help

all: setup dev ## Default: setup, then dev

help: ## Show every target, grouped by category
	@awk 'BEGIN {FS = ":.*## "} /^##@/ { printf "\n%s\n", substr($$0, 5) } /^[a-zA-Z_-]+:.*## / { printf "  make %-12s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Building

setup: ## Install XcodeGen if missing and generate the Xcode project
	command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	xcodegen generate

generate: ## Regenerate the Xcode project from project.yml
	xcodegen generate

dev: generate close ## Delete the old Debug build, build, then open it
	rm -rf $(BUILD_DIR)/Debug
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug CONFIGURATION_BUILD_DIR="$(CURDIR)/$(BUILD_DIR)/Debug" build
	open $(DEBUG_APP)

build: generate ## Release build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release CONFIGURATION_BUILD_DIR="$(CURDIR)/$(BUILD_DIR)/Release" build

clean: ## Remove build/
	rm -rf $(BUILD_DIR)

open: ## Open the dev (Debug) app
	open $(DEBUG_APP)

close: ## Quit the running app
	pkill -x $(APP_NAME) || true

##@ Production

install: build ## Release build, installed to /Applications
	rm -rf $(INSTALL_APP)
	cp -R $(RELEASE_APP) $(INSTALL_APP)

uninstall: close ## Quit and remove the installed app
	rm -rf $(INSTALL_APP)

reinstall: uninstall install ## Uninstall, then install

install-open: close install ## Install, then open the installed app
	open $(INSTALL_APP)

##@ Agent rules

AGENT_RULES ?= $(HOME)/Sites/agent-rules

rules: ## Sync shared agent rules from agent-rules into docs/rules/
	@$(AGENT_RULES)/bin/agent-rules sync "$(CURDIR)"

rules-check: ## Show what `make rules` would change (exit 1 if anything)
	@$(AGENT_RULES)/bin/agent-rules check "$(CURDIR)"
