#!/bin/bash

set -e

# Function to display error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

# Build the release bundle
echo "Building the release bundle..."
BUILD_OUTPUT=$(xcodebuild -workspace EmpowerPlant.xcworkspace -scheme EmpowerPlant -configuration Release clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1)

# Extract the first path to the .app from the build output
APP_PATH=$(echo "$BUILD_OUTPUT" | grep -Eo '/[^ ]+\.app($| )' | sed 's/ $//' | head -n 1)
ZIP_PATH="EmpowerPlant_release.zip"

# Check if the .app path was extracted successfully
if [ ! -d "$APP_PATH" ]; then
    error_exit "Failed to find .app path in the xcodebuild output."
fi

# Zip the .app file
echo "Zipping up the .app file to $ZIP_PATH..."
zip -rq "$ZIP_PATH" "$APP_PATH"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "gh is not installed, installing now..."
    
    # Install gh via Homebrew for macOS
    if ! command -v brew &> /dev/null; then
        # Install Homebrew if it's not installed
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew."
    fi

    brew install gh || error_exit "Failed to install gh."
fi

# Get release version
if [ "$#" -eq 1 ]; then
    TAG="$1"
else
    # Fetch the most recent release tag using gh and sort
    LATEST_RELEASE=$(gh release list | sort -V | tail -n 1 | awk '{print $1}')
    if [ -z "$LATEST_RELEASE" ]; then
        LATEST_RELEASE="0.0.0"
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

