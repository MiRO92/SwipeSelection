ifdef sim
    export ARCHS = x86_64
    export TARGET = simulator:latest:13.0
else
    export ARCHS = arm64 arm64e
    export TARGET = iphone:clang:latest:13.0
endif

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeSelection
SwipeSelection_FILES = $(filter-out Tweak.m, $(wildcard *.mm *.m)) Tweak.xm
SwipeSelection_FRAMEWORKS = UIKit
SwipeSelection_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

ifdef sim
setup:: clean all
    @echo ""
    @echo -ne "Removing old dylib... "
    @rm -f /opt/simject/$(TWEAK_NAME).dylib
    @echo "Done"
    @echo -ne "Copying dylib into simject folder... "
    @cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib &>/dev/null
    @echo "Done"
    @echo -ne "Copying plist into simject folder... "
    @cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject &>/dev/null
    @echo "Done"
    @echo -ne "Codesigning dylib... "
    @codesign -f -s - /opt/simject/$(TWEAK_NAME).dylib &>/dev/null
    @echo "Done"
    @echo ""
else
	SUBPROJECTS += SwipeSelectionPrefs
endif

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"

before-stage::
	find . -name ".DS_Store" -type f -delete
