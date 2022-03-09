
## Setup
- install XCode
- iPhone 11 tested
- iPhone 14.4

`pod install`

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