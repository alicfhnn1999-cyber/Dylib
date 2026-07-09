TARGET := iphone:clang:latest:15.0

ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WelcomeTweak

WelcomeTweak_FILES = Tweak.x
WelcomeTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
