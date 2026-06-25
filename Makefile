BUILD_INFO ?= .github/build-info.json
MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
GLUON_DIR ?= gluon
PATCHES_DIR ?= patches
PREPARE_SCRIPT := contrib/prepare-gluon.sh
UPDATE_SCRIPT := contrib/update-patches.sh

.PHONY: clean default help test update refresh-patches update-patches

default: help

help:
	@echo "Available targets:"
	@echo "  clean             Remove gluon directories"
	@echo "  update            Prepare gluon and link site directory"
	@echo "  update-patches    Update patch set from current build info"
	@echo "  refresh-patches   Run update and update-patches"

update:
	@bash $(PREPARE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"
	@ln -snf "$(MAKEFILE_DIR)" gluon/site

update-patches:
	@bash $(UPDATE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"

refresh-patches: update update-patches
	@echo "Patches refreshed successfully"

clean:
	@rm -rf "$(GLUON_DIR)"
