#!/bin/sh

if which sentry-cli >/dev/null; then
    if [ -f .env ] && grep -q "^SENTRY_ORG=" .env && grep -q "^SENTRY_PROJECT=" .env; then
        export $(grep -v '^#' .env | sed '/^\s*$/d' | xargs)
    else
        echo "[ERROR] .env does not exist or does not have SENTRY_ORG and SENTRY_PROJECT defined"
        exit 1
    fi
    if [ ! -n "$SENTRY_AUTH_TOKEN" ]; then
        if [ -f ~/.sentryclirc ]; then
            export SENTRY_AUTH_TOKEN=$(grep -oE "token=([^\n\r]*)$" ~/.sentryclirc | cut -d'=' -f2)
            echo "Using SENTRY_AUTH_TOKEN from .sentryclirc."
        fi
        if [ -f ~/.zshrc ] && grep -q "export SENTRY_AUTH_TOKEN" ~/.zshrc; then
            grep -m 1 "export SENTRY_AUTH_TOKEN" ~/.zshrc > /tmp/ios.sentry-build.tmp && source /tmp/ios.sentry-build.tmp && rm /tmp/ios.sentry-build.tmp
            echo "Using SENTRY_AUTH_TOKEN from .zshrc."
        fi
    fi
    if [ ! -n "$SENTRY_AUTH_TOKEN" ]; then
        echo "[ERROR] must provide SENTRY_AUTH_TOKEN either through command line, .zshrc or .sentryclirc"
        exit 1
    fi

    ERROR=$(sentry-cli upload-dif --force-foreground --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
    if [ ! $? -eq 0 ]; then
        echo "warning: sentry-cli - $ERROR"
    fi
else
    echo "[ERROR] sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
    exit 1
fi
