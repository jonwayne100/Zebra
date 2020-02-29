ARCHS = armv7 arm64 arm64e
TARGET = iphone::10.3:9.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = supersling.m
supersling_INSTALL_PATH = /usr/libexec/zebra

include $(THEOS_MAKE_PATH)/tool.mk

after-stage::
	$(ECHO_NOTHING)$(FAKEROOT) chown root:wheel $(THEOS_STAGING_DIR)/Library/LaunchDaemons/xyz.willy.supersling.plist$(ECHO_END)
