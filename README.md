## Overview
This app uses UIKit

## Setup
- install XCode
- iPhone 11 tested
- iPhone 14.4

`pod install`

The `se` tag is set in AppDelegate, not build configuration files.

## Run
Click Play button

## Bootstrapping iOS App
Followed for ViewController -> Embed In -> Navigation Controller, and Basic Styling
https://www.youtube.com/watch?v=LbAd2FIlnos

Segue's
1. CMD+Click EmpowerPlantViewController icon (1st of 3) on Storyboard, drag to next ViewController
2. Click the new segueu line arrow -> Storyboard Segue options -> Identifier, set as goToCart


Storyboard > ViewController > Navigation Item > BackButton renaming does not work


Dragged 'Checkout' button to bottom but it displays in middle in the virtual device, maybe because added constraints for Horizontal/Vertical Orientation.


`pod init` created Podfile but not Pods folder in XCode, like /cocoa demo has.
`pod install`
```
 ~/thinkocapo/EmpowerPlant   master ±   pod install
Analyzing dependencies
Pre-downloading: `Sentry` from `https://github.com/getsentry/sentry-cocoa.git`, tag `7.10.0`
Downloading dependencies
Installing Sentry (7.10.0)
Generating Pods project
Integrating client project

[!] Please close any current Xcode sessions and use `EmpowerPlant.xcworkspace` for this project from now on.
Pod installation complete! There is 1 dependency from the Podfile and 1 total pod installed.

[!] Your project does not explicitly specify the CocoaPods master specs repo. Since CDN is now used as the default, you may safely remove it from your repos directory via `pod repo remove master`. To suppress this warning please add `warn_for_unused_master_specs_repo => false` to your Podfile.
```

Problem - 'xcode not creating pods directory'
"Closing current project then re-open with new .xcworskpace will solve the issue."
"You should open .xcworkspace, not .xcodeproj."
XCode > File > Open > select the project's .xcoworkspace file, not the entire project directory
https://stackoverflow.com/questions/32906165/xcode-not-detecting-pods-directory
https://stackoverflow.com/questions/47343066/pod-files-not-showing-up-on-xcode

TODO - need upload debug symbols.

https://programmingwithswift.com/add-core-data-to-existing-ios-project/



"After that, I'll show you how to conform your managed object to Decodable"
https://www.donnywals.com/using-codable-with-core-data-and-nsmanagedobject/
JSON into Swift objects.

followed this...
https://cocoacasts.com/networking-fundamentals-how-to-make-an-http-request-in-swift

3/28

class vs extension...

https://developer.apple.com/forums/thread/50610



SHOPPING CART

ModelController - boilerplate...https://code.tutsplus.com/tutorials/the-right-way-to-share-state-between-swift-view-controllers--cms-28474

Data Container - boilerplate...

Singleton Pattern - easy, https://betterprogramming.pub/5-ways-to-pass-data-between-view-controllers-18acb467f5ec class Settings

File I/O - why not?

CoreData - easy (already using)

Segue - https://levelup.gitconnected.com/swift-xcode-sharing-data-between-view-controllers-8d270e99ca1e, going back and forth between controllers, could present problems with persistence.


```
let id: Int
let title: String
let description: String
let descriptionfull: String
let img: String
let imgcropped: String
let price: Int
```

If developing locally, must use
```
"http://127.0.0.1:8080/success"
```
and not
```
"localhost:8080/success"
```


GET requests must be
```
let task = URLSession.shared.dataTask(with: url) { data, response, error in
```
POST requests must be
```
let task = URLSession.shared.dataTask(with: request) { data, response, error in
```

Swift Version: X

## Creating release and uploading app

- Create debug and release builds + locate them on your disk + zip up accordingly (`EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`)
- Create release manually using UI (https://github.com/sentry-demos/ios/releases/new)
    - Increment version accordingly (release-title)
    - Upload `EmpowerPlant_debug.zip` + `EmpowerPlant_release.zip`

See https://github.com/sentry-demos/ios/releases/tag/0.0.1 for a sample release

<<<<<<< HEAD
Swift Version: X

## Upgrading Sentry SDK
Check out a new branch so you can open a PR.

1. Xcode -> Podfile, increment the sdk version.
2. pod update, or pod install if pod updating is hanging.
3. Click 'Play' button
=======
Note: TDA must be restarted for it to pick up new version
>>>>>>> master
