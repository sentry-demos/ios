#!/bin/bash

# Sentry dSYM Upload Script
# Add this as a "Run Script" build phase in Xcode after your "Compile Sources" phase

# Add Homebrew to PATH for Apple Silicon Macs
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# Check if sentry-cli is installed
if which sentry-cli >/dev/null; then
    # Set your Sentry configuration
    export SENTRY_ORG=sentry-demos  # Replace with your org
    export SENTRY_PROJECT=empowerplant-ios  # Replace with your project 
    export SENTRY_AUTH_TOKEN=sntrys_YOUR_TOKEN_HERE  # Replace with your auth token
    
    echo "Uploading dSYMs to Sentry..."
    
    # Upload dSYMs with source context for better debugging
    ERROR=$(sentry-cli debug-files upload \
        --include-sources \
        "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
    
    if [ ! $? -eq 0 ]; then
        echo "warning: sentry-cli - $ERROR"
    else
        echo "Successfully uploaded dSYMs to Sentry"
    fi
else
    echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
    echo "Install with: brew install getsentry/tools/sentry-cli"
fi
