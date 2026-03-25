#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if [ $CONFIGURATION == 'Test' ]; then
    echo "Will not upload debug symbols for test build."
    exit 0
fi

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

    sentry-cli upload-dif --force-foreground --include-sources -o $SENTRY_ORG -p $SENTRY_PROJECT --auth-token $SENTRY_AUTH_TOKEN "$DWARF_DSYM_FOLDER_PATH"

    # Upload simulator system library symbols for CFNetwork and libdispatch.
    # Sentry's server-side symbolication only has device symbols; simulator
    # builds use different UUIDs so we must upload them explicitly.
    # We resolve the runtime root for the target device's specific runtime,
    # checking both old-style (Profiles/Runtimes) and iOS 17+ (Volumes-based)
    # layouts via bundlePath from simctl.
    if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
        # Use TARGET_DEVICE_IDENTIFIER (Xcode build var) to find the target
        # device's runtime, then resolve its RuntimeRoot on disk.
        SIM_RUNTIME_ROOT=$(xcrun simctl list devices -j | python3 -c "
import sys, json, os, subprocess
target_udid = '${TARGET_DEVICE_IDENTIFIER}'
data = json.load(sys.stdin)
target_runtime = None
for runtime_id, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == target_udid:
            target_runtime = runtime_id
            break
    if target_runtime:
        break
if not target_runtime:
    sys.exit(1)
# Look up the runtime's bundlePath
rt_data = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'runtimes', '-j']))
for rt in rt_data.get('runtimes', []):
    if rt.get('identifier') == target_runtime:
        root = rt.get('bundlePath', '') + '/Contents/Resources/RuntimeRoot'
        if os.path.isdir(root):
            print(root)
        break
" 2>/dev/null)

        if [ -n "$SIM_RUNTIME_ROOT" ] && [ -d "$SIM_RUNTIME_ROOT" ]; then
            echo "Uploading simulator system symbols from $SIM_RUNTIME_ROOT"
            UPLOAD_PATHS=""
            for lib in \
                "$SIM_RUNTIME_ROOT/System/Library/Frameworks/CFNetwork.framework/CFNetwork" \
                "$SIM_RUNTIME_ROOT/usr/lib/system/libdispatch.dylib" \
                "$SIM_RUNTIME_ROOT/usr/lib/system/introspection/libdispatch.dylib"; do
                [ -f "$lib" ] && UPLOAD_PATHS="$UPLOAD_PATHS \"$lib\""
            done
            if [ -n "$UPLOAD_PATHS" ]; then
                eval sentry-cli upload-dif --force-foreground -o $SENTRY_ORG -p $SENTRY_PROJECT --auth-token $SENTRY_AUTH_TOKEN $UPLOAD_PATHS
            fi
        else
            echo "warning: could not determine simulator runtime root for device $TARGET_DEVICE_IDENTIFIER, skipping system symbol upload"
        fi
    fi
else
    echo "error: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
    exit 1
fi
