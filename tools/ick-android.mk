# Shared ABI/header metadata; only this project's runner target is selected.
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
AICI_ROOT ?= $(ROOT)/.ai-ci-ick
include $(AICI_ROOT)/ick-android/Makefile
.DEFAULT_GOAL := runner
ANDROID_API ?= 21
RUNNER ?= $(ROOT)/build/powervr-primitives-$(ABI)
RUNNER_NDK_CC = $(NDK_BIN)/$(NDK_TARGET_$(ABI))$(ANDROID_API)-clang

.PHONY: runner
runner:
	test -x "$(ICK_COMPILER)"
	test "$$($(ICK_COMPILER) -dumpmachine)" = "$(GNU_TARGET)"
	test -f "$(ICK_BUILTIN_INCLUDE)/stddef.h"
	test -x "$(RUNNER_NDK_CC)"
	mkdir -p "$(dir $(RUNNER))"
	"$(ICK_COMPILER)" $(ICK_EXTRA_FLAGS) $(ICK_NDK_BASE_FLAGS) -D__ANDROID_API__=$(ANDROID_API) -D__ANDROID_MIN_SDK_VERSION__=$(ANDROID_API) -std=c11 -O2 -Wall -Wextra -fPIE -S "$(ROOT)/tools/powervr_primitives.c" -o "$(RUNNER).s"
	"$(RUNNER_NDK_CC)" $(TARGET_FLAGS) -fPIE -c "$(RUNNER).s" -o "$(RUNNER).o"
	"$(RUNNER_NDK_CC)" -pie "$(RUNNER).o" -o "$(RUNNER)" -lEGL -lGLESv3 -lm
