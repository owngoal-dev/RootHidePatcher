ARCHS = arm64
TARGET = iphone:latest:15.0
DEB_ARCH = iphoneos-arm64e
IPHONEOS_DEPLOYMENT_TARGET = 15.0

INSTALL_TARGET_PROCESSES = Patcher

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

XCODE_SCHEME = UmbraPatcher

XCODEPROJ_NAME = UmbraPatcher

UmbraPatcher_XCODEFLAGS = MARKETING_VERSION=$(THEOS_PACKAGE_BASE_VERSION) \
	IPHONEOS_DEPLOYMENT_TARGET="$(IPHONEOS_DEPLOYMENT_TARGET)" \
	CODE_SIGN_IDENTITY="" \
	AD_HOC_CODE_SIGNING_ALLOWED=YES
UmbraPatcher_XCODE_SCHEME = $(XCODE_SCHEME)
UmbraPatcher_CODESIGN_FLAGS = -Sentitlements.plist
UmbraPatcher_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/xcodeproj.mk

clean::
	rm -rf ./packages/*


after-install::
	install.exec 'uiopen -b wiki.qaq.umbra.patcher'
