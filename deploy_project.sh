#!/bin/bash

set -eo pipefail

# Unsigned Release builds for fastlane/Fastfile's release lane.
#
# Usage: ./deploy_project.sh <marketing-version> <build-code> <release-tag>
# Example: ./deploy_project.sh 26.10.7 261007 26.10.7
#
# marketing-version is CFBundleShortVersionString (YY.M.D).
# build-code is CFBundleVersion (YYMMDD, digits only).
# release-tag is the GitHub release tag (YY.M.D, or YY.M.D-N if that tag exists).
#
# Requires SENTRY_ORG, SENTRY_PROJECT, and SENTRY_AUTH_TOKEN.
# Builds two unsigned Release products:
# - build/EmpowerPlant.ipa from a device archive. The lane uploads it and the
#   archive's dSYMs to Sentry.
# - EmpowerPlant_release.zip, a simulator EmpowerPlant.app. Empower's TDA
#   installs that asset from the newest GitHub release on a Sauce Labs
#   simulator, so the zip keeps the build/Build/Products/Release-iphonesimulator/
#   layout of 0.0.44's zip.
# The workflow publishes both on master.

error_exit() {
    echo "$1" >&2
    exit 1
}

if [ "$#" -ne 3 ]; then
    error_exit "Usage: ./deploy_project.sh <marketing-version> <build-code> <release-tag>"
fi

MARKETING_VERSION="$1"
BUILD_CODE="$2"
RELEASE_TAG="$3"

case "$MARKETING_VERSION" in
    ''|*[!0-9.]*) error_exit "marketing version must look like YY.M.D, got: $MARKETING_VERSION" ;;
esac
case "$BUILD_CODE" in
    ''|*[!0-9]*) error_exit "build code must be digits (YYMMDD), got: $BUILD_CODE" ;;
esac
case "$RELEASE_TAG" in
    ''|*[!0-9.-]*) error_exit "release tag must look like YY.M.D or YY.M.D-N, got: $RELEASE_TAG" ;;
esac

if [ -z "${SENTRY_ORG}" ] || [ -z "${SENTRY_PROJECT}" ] || [ -z "${SENTRY_AUTH_TOKEN}" ]; then
    error_exit "SENTRY_ORG, SENTRY_PROJECT, and SENTRY_AUTH_TOKEN must be set."
fi

cd "$(dirname "$0")"

INFO_PLIST="EmpowerPlant/Resources/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MARKETING_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_CODE" "$INFO_PLIST"

echo "Building one Release archive ($MARKETING_VERSION / $BUILD_CODE)..."
# macos-15 defaults to Xcode 16.4 (Swift 6.1). That tools version loads
# sentry-cocoa 9.32.0's Package@swift-6.1.swift and rejects the KSCrash
# revision as an unstable dependency of stable 9.32.0. Swift 6.2 (Xcode 26)
# ignores that revision unless the V10 trait is enabled or SDK_V10=1.
# Local Xcode already resolved the pin that way.
unset SDK_V10
export DEVELOPER_DIR=/Applications/Xcode_26.3.app
if [ ! -d "$DEVELOPER_DIR" ]; then
    error_exit "Need $DEVELOPER_DIR so SwiftPM can resolve sentry-cocoa 9.32.0 without the unused KSCrash revision."
fi
SENTRY_ORG="$SENTRY_ORG" \
SENTRY_PROJECT="$SENTRY_PROJECT" \
SENTRY_AUTH_TOKEN="$SENTRY_AUTH_TOKEN" \
xcodebuild archive \
    -project EmpowerPlant.xcodeproj \
    -scheme EmpowerPlant \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath build/EmpowerPlant.xcarchive \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

APP_PATH="build/EmpowerPlant.xcarchive/Products/Applications/EmpowerPlant.app"
if [ ! -d "$APP_PATH" ]; then
    error_exit "Archive did not contain $APP_PATH"
fi

# Unsigned IPA: Payload/*.app, the same .app that is inside the archive.
# This repo has no Apple distribution certificate to sign it with.
STAGE="build/ipa-stage"
IPA_PATH="build/EmpowerPlant.ipa"
rm -rf "$STAGE" "$IPA_PATH"
mkdir -p "$STAGE/Payload"
cp -R "$APP_PATH" "$STAGE/Payload/"
(
    cd "$STAGE"
    zip -r -y "../EmpowerPlant.ipa" Payload
)

echo "Building the Release simulator app..."
SIM_PRODUCTS="build/Build/Products/Release-iphonesimulator"
SIM_APP_PATH="$SIM_PRODUCTS/EmpowerPlant.app"
ZIP_PATH="EmpowerPlant_release.zip"
rm -rf "$SIM_PRODUCTS" "$ZIP_PATH"
SENTRY_ORG="$SENTRY_ORG" \
SENTRY_PROJECT="$SENTRY_PROJECT" \
SENTRY_AUTH_TOKEN="$SENTRY_AUTH_TOKEN" \
xcodebuild build \
    -project EmpowerPlant.xcodeproj \
    -scheme EmpowerPlant \
    -configuration Release \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath build \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

if [ ! -d "$SIM_APP_PATH" ]; then
    error_exit "Simulator build did not produce $SIM_APP_PATH"
fi

zip -r -q "$ZIP_PATH" "./$SIM_APP_PATH"

# Check what the TDA will install: the zipped app must be a simulator build.
ZIP_CHECK="build/zip-check"
rm -rf "$ZIP_CHECK"
mkdir -p "$ZIP_CHECK"
unzip -q "$ZIP_PATH" -d "$ZIP_CHECK"
ZIPPED_PLIST="$ZIP_CHECK/$SIM_APP_PATH/Info.plist"
if [ ! -f "$ZIPPED_PLIST" ]; then
    error_exit "$ZIP_PATH has no $SIM_APP_PATH/Info.plist"
fi
PLATFORM=$(/usr/libexec/PlistBuddy -c "Print :DTPlatformName" "$ZIPPED_PLIST")
if [ "$PLATFORM" != "iphonesimulator" ]; then
    error_exit "$ZIP_PATH holds a $PLATFORM app, expected iphonesimulator"
fi
rm -rf "$ZIP_CHECK"

echo "Archive, ${IPA_PATH}, and ${ZIP_PATH} are ready for ${RELEASE_TAG}."
