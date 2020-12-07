include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SwipeSelectionPrefs
SwipeSelectionPrefs_FILES = $(wildcard *.mm  *.m) ../SSHapticsManager.m
SwipeSelectionPrefs_INSTALL_PATH = /Library/PreferenceBundles
SwipeSelectionPrefs_FRAMEWORKS = UIKit MessageUI
SwipeSelectionPrefs_PRIVATE_FRAMEWORKS = Preferences OnBoardingKit CoreGraphics
SwipeSelectionPrefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs

SwipeSelectionPrefs_LDFLAGS = -lMobileGestalt
SwipeSelectionPrefs_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipeSelection.plist$(ECHO_END)
