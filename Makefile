# Build the app for both phones, keeping the licence page current.
#
#   make            Android and iOS
#   make android    Android APK
#   make ios        iOS app, unsigned
#   make licenses   regenerate the native licence list
#   make clean      remove build output
#
# The licence page is generated from artefacts that only a build produces:
# Gradle's wrapper and CocoaPods' acknowledgements. Whichever is missing is
# created by a debug build first, so a fresh checkout needs no extra steps.
# Re-run `make licenses` after changing a dependency.

.DEFAULT_GOAL := all

# Both platforms write into the same build directory.
.NOTPARALLEL:

.PHONY: all android ios licenses clean

all: android ios

android: licenses
	flutter build apk

# Shipping needs a signing identity: `flutter build ipa` instead, or
# `flutter build appbundle` for Play.
ios: licenses
	flutter build ios --no-codesign

licenses: android/gradlew ios/Pods
	flutter pub get
	dart run tool/update_native_licenses.dart

# Both are build outputs rather than checked-in files.
android/gradlew:
	flutter build apk --debug

ios/Pods:
	flutter build ios --debug --no-codesign

clean:
	flutter clean
	rm -rf ios/Pods
