BUILD_INFO ?= .github/build-info.json
MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
GLUON_DIR ?= gluon
PATCHES_DIR ?= patches
PREPARE_SCRIPT := contrib/prepare-gluon.sh
UPDATE_SCRIPT := contrib/update-patches.sh

.PHONY: update refresh-patches update-patches

update:
	@bash $(PREPARE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"
	@ln -snf "$(MAKEFILE_DIR)" gluon/site

update-patches:
	@bash $(UPDATE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"

refresh-patches: update update-patches
	@echo "Patches refreshed successfully"
