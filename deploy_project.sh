#!/bin/bash

set -eox pipefail

# Function to display error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

VERSION_INPUT=${1}
SENTRY_ORG_INPUT=${2}
SENTRY_PROJECT_INPUT=${3}
SENTRY_AUTH_TOKEN_INPUT=${4}

# Build the release bundle
echo "Building the release bundle..."
SENTRY_ORG=$SENTRY_ORG_INPUT SENTRY_PROJECT=$SENTRY_PROJECT_INPUT SENTRY_AUTH_TOKEN=$SENTRY_AUTH_TOKEN_INPUT xcodebuild -workspace EmpowerPlant.xcworkspace -scheme EmpowerPlant -configuration Release -derivedDataPath build -destination "platform=iOS Simulator,OS=latest,name=iPhone 14" clean build
zip -r EmpowerPlant_release.zip ./build/Build/Products/Release-iphonesimulator/EmpowerPlant.app
ZIP_PATH="./EmpowerPlant_release.zip"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  error_exit "gh is not installed, make sure you run 'make init' (see README.md)."
fi

# Get release version
if [ "$#" -eq 1 ]; then
    TAG="$1"
else
    echo "Release name not provided as CLI argument, incrementing patch version of latest release in GH then..."
    # Fetch the most recent release tag using gh and sort
    LATEST_RELEASE=$(gh release list | sort -V | tail -n 1 | awk '{print $1}')
    if [ -z "$LATEST_RELEASE" ]; then
        error_exit "Could not find any existing releases in GitHub. This is either a bug in the script or this is being run in a new repo with no releases."
    fi
    # Split the version and increment the last digit
    IFS='.' read -ra VERSION_PARTS <<< "$LATEST_RELEASE"
    LAST_DIGIT_INCREMENTED=$(( ${VERSION_PARTS[2]} + 1 ))
    TAG="${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.$LAST_DIGIT_INCREMENTED"
fi

TITLE="$TAG"
NOTES="Generated automatically by ios/deploy_project.sh"

# Create the GitHub release with the attached iOS build zip
gh release create $TAG $ZIP_PATH -t "$TITLE" -n "$NOTES" || error_exit "Failed to create GitHub release."

echo "Release created successfully with version $TAG!"

