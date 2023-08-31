## Overview
This app uses UIKit

## Setup
- install XCode
- iPhone 11 tested
- iPhone 14.4

`pod install`

Add `.env` file with the following in it:
```
SENTRY_ORG=<your org slug>
SENTRY_PROJECT=<your project slug>
```

Make sure `sentry-cli info` succeeds, i.e. you have SENTRY_AUTH_TOKEN set somewhere.

## Run
Click Play button

## Bootstrapping iOS App
Want to know how this app was originally set up? See https://www.notion.so/sentry/Bootstrapping-iOS-app-abcd0da2bca64cbcbf6d086fa5188caf

## Troubleshooting
### Unable to load contents of file list: 'xxxxx/Pods/Target Support Files/... .xcfilelist'
- `sudo gem update cocoapods --pre`
- `pod update`
- Product -> Clean Build Folder...
- Product -> Build
### [!] CocoaPods could not find compatible versions for pod "SentryPrivate":
Run `pod repo update` then try again

## Creating release and uploading app

- Create debug and release builds + locate them on your disk + zip up accordingly (`EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`)
- Create release manually using UI (https://github.com/sentry-demos/ios/releases/new)
    - Increment version accordingly (release-title)
    - Upload `EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`

See https://github.com/sentry-demos/ios/releases/tag/0.0.1 for a sample release

Note: TDA must be restarted for it to pick up new version
