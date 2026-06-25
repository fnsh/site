BUILD_INFO ?= .github/build-info.json
GLUON_DIR ?= gluon
PATCHES_DIR ?= patches
PREPARE_SCRIPT := contrib/prepare-gluon.sh
UPDATE_SCRIPT := contrib/update-patches.sh

.PHONY: prepare update

prepare:
	@bash $(PREPARE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"

update:
	@bash $(UPDATE_SCRIPT) "$(BUILD_INFO)" "$(GLUON_DIR)" "$(PATCHES_DIR)"