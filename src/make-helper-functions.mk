
default_target: all

.SECONDARY:

project_root := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
export project_root

define newline


endef

define include_config_if_exits
  ifeq ($(shell test -e "$(project_root)/config/$(1)" && echo -n yes),yes)
    include $(project_root)/config/$(1)
    ifeq ($(shell test -e "$(project_root)/config/user_config_override" && echo -n yes),yes)
      include $(project_root)/config/user_config_override
    endif
  endif
endef

VARS_OLD := $(subst %,,$(subst *,,$(.VARIABLES)))

ifeq ($(shell test -e "$(project_root)/config/user_config_override" && echo -n yes),yes)
include $(project_root)/config/user_config_override
endif

$(eval $(call include_config_if_exits,default/config))
$(foreach config,$(CONFIG_PATH),$(eval $(call include_config_if_exits,$(config)/config)))

ifdef REPO-$(DISTRO)
  REPO = $(REPO-$(DISTRO))
endif

ifdef REPO-$(DISTRO)-$(RELEASE)
  REPO = $(REPO-$(DISTRO)-$(RELEASE))
endif

ifdef CHROOT_REPO-$(DISTRO)
  CHROOT_REPO = $(CHROOT_REPO-$(DISTRO))
endif

ifdef CHROOT_REPO-$(DISTRO)-$(RELEASE)
  CHROOT_REPO = $(CHROOT_REPO-$(DISTRO)-$(RELEASE))
endif

CONFIG_VARS := $(sort $(filter-out $(VARS_OLD) VARS_OLD,$(subst %,,$(subst *,,$(.VARIABLES)))))
IMGSIZE := $(shell echo "$(IMGSIZE)" | sed 's/\s*//g')
export $(CONFIG_VARS)

CONF = user_config_override

include $(project_root)/src/repositories.mk

export PATH := /helper/bin:$(project_root)/script/:/sbin:/usr/sbin:$(PATH):$(project_root)/build/bin:$(project_root)/bin

include $(project_root)/src/package_list.mk

export DEBIAN_FRONTEND=noninteractive

generate_make_build_dependencies_for_debs:
	export DEP_PREFIX=$(DEP_PREFIX); \
	export DEP_SUFFIX=$(DEP_SUFFIX); \
	if [ -n "$(TMP_TARGET_FILE)" ]; \
	  then generate_make_build_dependencies_for_debs.sh >"$(TMP_TARGET_FILE)"; \
	  else generate_make_build_dependencies_for_debs.sh; \
	fi

%/.dir:
	mkdir -p "$(dir $@)"
	touch "$@"

chroot@%:
	export PROMPT_COMMAND="export PS1='$@ (\u)> '"; \
	uexec --allow-setgroups chroot_qemu_static.sh "$(realpath $(patsubst chroot@%,%,$@))" /bin/bash

clean:
	! echo -n "Please use one of:\n * make clean-build\t# remove all files built for the target image (includes the image)\n * make clean-build-all\t# remove all files that have been built\n * make clean-repo\t# remove the downloaded repos\n * make reset-repo\t# clean up all changes made to the repo & update it if possible\n * make clean-all\t# same as 'make clean-repo clean-build'\n * make clean-all-all\t# same as 'make clean-repo clean-build-all'\n * make reset\t\t# same as 'make reset-repo clean-build'\n * make reset-all\t# same as 'make reset-repo clean-build-all'\n"

repo/.%.repo:
	branch="$(repo-branch@$(patsubst repo/.%.repo,%,$@))"; \
	source="$(repo-source@$(patsubst repo/.%.repo,%,$@))"; \
	mkdir -p "repo/$(patsubst repo/.%.repo,%,$@)" && cd "repo/$(patsubst repo/.%.repo,%,$@)" && git clone -b "$$branch" "$$source" . && git submodule init && git submodule update
	touch "repo/$(patsubst repo/.%.repo,%,$@)"
	touch "$@"

repo@%:
	make repo/.$(patsubst repo@%,%,$@).repo

clean-repo@%:
	rm -rf "repo/$(patsubst clean-repo@%,%,$@)"
	rm -f "repo/.$(patsubst clean-repo@%,%,$@).repo"

reset-repo@%:
	set -e; \
	repo="repo/$(patsubst reset-repo@%,%,$@)"; \
	source="$(repo-source@$(patsubst reset-repo@%,%,$@))"; \
	branch="$(repo-branch@$(patsubst reset-repo@%,%,$@))"; \
	if [ -d "$$repo/.git" ]; \
	then \
	  cd "$$repo"; \
	  git remote set-url origin "$$source"; \
	  git fetch origin || [ -z "$(FETCH_REQUIRED_TO_SUCCEED)" ]; \
	  find -maxdepth 1 -not -name .git -not -name . -exec rm -rf {} \;; \
	  git reset --hard; \
	  git -c checkout.defaultRemote=origin checkout -f --detach || true; \
	  git branch -D "$$branch" || true; \
	  git -c checkout.defaultRemote=origin checkout -f "$$branch" >/dev/null; \
	  git reset --hard >/dev/null; \
	  git submodule init; \
	  git submodule update; \
	  touch .; \
	  touch "../.$(patsubst reset-repo@%,%,$@).repo"; \
	fi

config-list:
	@$(foreach VAR,$(CONFIG_VARS), echo "$(VAR)" = "$($(VAR))"; )

config-after-update@%:
	@ set -e; \
	case "$(patsubst config-after-update@%,%,$@)" in \
	  "IMGSIZE"    ) $(MAKE) clean-image ;; \
	  "REPO"       ) $(MAKE) clean-fs ;; \
	  "CHROOT_REPO") $(MAKE) clean-fs ;; \
	  "KERNEL_DTB" ) $(MAKE) clean-fs ;; \
	  "IMAGE_NAME" ) $(MAKE) clean-image ;; \
	  "repo-branch@"*) $(MAKE) "reset-repo@$(patsubst config-after-update@repo-branch@%,%,$@)" ;; \
	  "repo-source@"*) $(MAKE) "reset-repo@$(patsubst config-after-update@repo-source@%,%,$@)" FETCH_REQUIRED_TO_SUCCEED=true ;; \
	  "UBOOT_DTB" | "UBOOT_CONFIG_TARGET" | "repo-source@uboot" | "repo-branch@uboot") \
	    $(MAKE) -C "$(project_root)/uboot/" clean-build \
	  ;; \
	  "KERNEL_CONFIG_TARGET" | "repo-source@linux" | "repo-branch@linux") \
	    $(MAKE) -C "$(project_root)/kernel/" clean-build \
	  ;; \
	esac

config-pre-set-check@%:
	@case "$(patsubst config-pre-set-check@%,%,$@)" in \
	  *) ;; \
	esac

config-set@%: config-pre-set-check@%
	@ if [ -z "$(TO)" ]; \
	  then echo "Usage: config-set@variablename TO=new_value"; \
	  false; \
	fi
	V="$(patsubst config-set@%,%,$@)"; \
	sed -i "/^$$V[ ]*=/d" "$(project_root)/config/$(CONF)" 2>&-; \
	echo "$$V = $(TO)" >> $(project_root)/config/$(CONF)
	@ $(MAKE) --no-print-directory OLD_VALUE="$($(patsubst config-set@%,%,$@))" "config-after-update@$(patsubst config-set@%,%,$@)"

config-unset@%:
	V="$(patsubst config-unset@%,%,$@)"; \
	sed -i "/^$$V[ ]*=/d" "$(project_root)/config/$(CONF)"
	@ $(MAKE) --no-print-directory OLD_VALUE="$($(patsubst config-unset@%,%,$@))" "config-after-update@$(patsubst config-unset@%,%,$@)"

clean-all: clean-repo clean-build
clean-all-all: clean-repo clean-build-all
reset: reset-repo clean-build
reset-all: reset-repo clean-build-all

.PHONY: all repo reset-repo clean-repo clean clean-all clean-all-all clean-build clean-build-all
