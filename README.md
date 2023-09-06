## Overview

An iOS app integrating Sentry to demo its various product features.

## Setup
- Install XCode
- In a terminal, run: 
    - `make init`
    - `sentry-cli login` (see [`sentry-cli` docs](https://docs.sentry.io/product/cli/) for more info)

## Run
Open Xcode and click the "Play" button or press ⌘R 

## Creating release and uploading app

- Create debug and release builds + locate them on your disk + zip up accordingly (`EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`)
- Create release manually using UI (https://github.com/sentry-demos/ios/releases/new)
    - Increment version accordingly (release-title)
    - Upload `EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`

See https://github.com/sentry-demos/ios/releases/tag/0.0.1 for a sample release

Note: TDA must be restarted for it to pick up new version
