#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if which sentry-cli >/dev/null; then

    # get SENTRY_ORG and SENTRY_PROJECT values
    if [ -n "${SENTRY_ORG}" ] && [ -n "${SENTRY_PROJECT}" ]; then
        echo "Using SENTRY_ORG and SENTRY_PROJECT environment variables."
    elif [ -f .env ] && grep -q "^SENTRY_ORG=" .env && grep -q "^SENTRY_PROJECT=" .env; then
        echo "Using SENTRY_ORG and SENTRY_PROJECT from .env file."
        export $(grep -v '^#' .env | sed '/^\s*$/d' | xargs)
    else
        echo "error: no SENTRY_ORG and SENTRY_PROJECT defined"
        exit 1
    fi
    
    # get SENTRY_AUTH_TOKEN value
    if [ -n "${SENTRY_AUTH_TOKEN}" ]; then
        echo "Using SENTRY_AUTH_TOKEN environment variable."
    else
        if [ -f ~/.sentryclirc ]; then
            export SENTRY_AUTH_TOKEN=$(grep -oE "token=(.*)$" ~/.sentryclirc | sed s/'token='//)
            echo "Using SENTRY_AUTH_TOKEN from .sentryclirc."
        fi
        if [ -f ~/.zshrc ] && grep -q "export SENTRY_AUTH_TOKEN" ~/.zshrc; then
            grep -m 1 "export SENTRY_AUTH_TOKEN" ~/.zshrc > /tmp/ios.sentry-build.tmp && source /tmp/ios.sentry-build.tmp && rm /tmp/ios.sentry-build.tmp
            echo "Using SENTRY_AUTH_TOKEN from .zshrc."
        fi
    fi
    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        echo "error: must provide SENTRY_AUTH_TOKEN either through command line, environment variable, .zshrc or .sentryclirc"
        exit 1
    fi

#    sentry-cli upload-dif --force-foreground --include-sources -o $SENTRY_ORG -p $SENTRY_PROJECT --auth-token $SENTRY_AUTH_TOKEN "$DWARF_DSYM_FOLDER_PATH"
else
    echo "error: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
    exit 1
fi
