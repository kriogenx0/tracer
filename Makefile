PROJECT := Tracer.xcodeproj
SCHEME := TracerApp
APP_NAME := Tracer
BUILD_DIR := build
DEBUG_APP := $(BUILD_DIR)/Debug/$(APP_NAME).app
RELEASE_APP := $(BUILD_DIR)/Release/$(APP_NAME).app
INSTALL_APP := $(HOME)/Applications/$(APP_NAME).app

.DEFAULT_GOAL := all
.PHONY: all setup generate dev build clean open close install uninstall reinstall

all: setup dev

setup:
	command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	xcodegen generate

generate:
	xcodegen generate

dev: generate
	rm -rf $(BUILD_DIR)/Debug
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug CONFIGURATION_BUILD_DIR="$(CURDIR)/$(BUILD_DIR)/Debug" build
	open $(DEBUG_APP)

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release CONFIGURATION_BUILD_DIR="$(CURDIR)/$(BUILD_DIR)/Release" build

clean:
	rm -rf $(BUILD_DIR)

open: build
	open $(RELEASE_APP)

close:
	pkill -x $(APP_NAME) || true

install: build
	mkdir -p $(HOME)/Applications
	rm -rf $(INSTALL_APP)
	cp -R $(RELEASE_APP) $(INSTALL_APP)

uninstall: close
	rm -rf $(INSTALL_APP)

reinstall: uninstall install
