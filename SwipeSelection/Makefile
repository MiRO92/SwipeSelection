ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SwipeSelection
SwipeSelection_FILES = $(wildcard *.mm  *.m) ../SSHapticsManager.m
SwipeSelection_INSTALL_PATH = /Library/PreferenceBundles
SwipeSelection_FRAMEWORKS = UIKit MessageUI
SwipeSelection_PRIVATE_FRAMEWORKS = Preferences OnBoardingKit CoreGraphics
SwipeSelection_EXTRA_FRAMEWORKS += Cephei CepheiPrefs

SwipeSelection_LDFLAGS = -lMobileGestalt
SwipeSelection_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipeSelection.plist$(ECHO_END)
