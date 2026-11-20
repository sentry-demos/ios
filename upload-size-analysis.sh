#!/bin/sh

# Upload an XCArchive (preferred) or IPA for Sentry Size Analysis.
# Auth matches upload-symbols.sh: SENTRY_ORG, SENTRY_PROJECT, and
# SENTRY_AUTH_TOKEN from the environment, .env, .sentryclirc, or .zshrc.
#
# Usage: ./upload-size-analysis.sh path/to/EmpowerPlant.xcarchive [Release]

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

ARCHIVE_PATH="${1:-}"
BUILD_CONFIGURATION="${2:-Release}"

if [ -z "$ARCHIVE_PATH" ] || [ ! -e "$ARCHIVE_PATH" ]; then
    echo "error: pass an existing XCArchive or IPA." >&2
    echo "example: ./upload-size-analysis.sh build/EmpowerPlant.xcarchive Release" >&2
    exit 1
fi

if ! which sentry-cli >/dev/null; then
    echo "error: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases" >&2
    exit 1
fi

if [ -n "${SENTRY_ORG}" ] && [ -n "${SENTRY_PROJECT}" ]; then
    echo "Using SENTRY_ORG and SENTRY_PROJECT environment variables."
elif [ -f .env ] && grep -q "^SENTRY_ORG=" .env && grep -q "^SENTRY_PROJECT=" .env; then
    echo "Using SENTRY_ORG and SENTRY_PROJECT from .env file."
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | sed '/^\s*$/d' | xargs)
else
    echo "error: no SENTRY_ORG and SENTRY_PROJECT defined" >&2
    exit 1
fi

if [ -n "${SENTRY_AUTH_TOKEN}" ]; then
    echo "Using SENTRY_AUTH_TOKEN environment variable."
else
    if [ -f ~/.sentryclirc ]; then
        SENTRY_AUTH_TOKEN="$(grep -oE "token=(.*)$" ~/.sentryclirc | sed s/'token='//)"
        export SENTRY_AUTH_TOKEN
        echo "Using SENTRY_AUTH_TOKEN from .sentryclirc."
    fi
    if [ -f ~/.zshrc ] && grep -q "export SENTRY_AUTH_TOKEN" ~/.zshrc; then
        # shellcheck source=/dev/null
        grep -m 1 "export SENTRY_AUTH_TOKEN" ~/.zshrc > /tmp/ios.sentry-build.tmp && . /tmp/ios.sentry-build.tmp && rm /tmp/ios.sentry-build.tmp
        echo "Using SENTRY_AUTH_TOKEN from .zshrc."
    fi
fi
if [ -z "$SENTRY_AUTH_TOKEN" ]; then
    echo "error: must provide SENTRY_AUTH_TOKEN either through command line, environment variable, .zshrc or .sentryclirc" >&2
    exit 1
fi

set -- sentry-cli build upload "$ARCHIVE_PATH" \
    --org "$SENTRY_ORG" \
    --project "$SENTRY_PROJECT" \
    --build-configuration "$BUILD_CONFIGURATION" \
    --auth-token "$SENTRY_AUTH_TOKEN"

HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || true)"
HEAD_REF="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [ -n "$HEAD_SHA" ]; then
    set -- "$@" --head-sha "$HEAD_SHA"
fi
if [ -n "$HEAD_REF" ] && [ "$HEAD_REF" != "HEAD" ]; then
    set -- "$@" --head-ref "$HEAD_REF" --vcs-provider github --head-repo-name "sentry-demos/ios"
fi

"$@"
