# Project wiring; archive validation and compiler metadata live in ai-ci.
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
ICK_INTERFACE ?= $(ROOT)/.ai-ci-ick/ick-android/Makefile
ICK_ARTIFACTS ?= $(ROOT)/.ick-toolchains
ICK_ROOT ?= $(ROOT)/build/ick
ABIS = armeabi-v7a arm64-v8a
RESTORED = $(addsuffix /.restored,$(addprefix $(ICK_ROOT)/,$(ABIS)))

.PHONY: restore
restore: $(RESTORED)

$(ICK_ROOT)/%/.restored: $(ICK_ARTIFACTS)/shader-ick-%.tar.gz
	$(MAKE) -f "$(ICK_INTERFACE)" restore-stage ABI="$*" ICK_STAGE="$(@D)" ICK_ARCHIVE="$<"
	touch "$@"
