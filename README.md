## Overview

Empower Plants is an iOS shop that demos Sentry. The app uses the Sentry Cocoa SDK **9.32.0** (`SentrySPM`, `import SentrySwift`).

The DSN in `EmpowerPlant/Main/AppDelegate.swift` sends events to the demo organization, project **ios**. A commented wassim-test DSN sits above `options.dsn` so that project can be restored. Leave the active DSN on the demo ios project.

Sentry's app-hang watcher is off (`enableAppHangTracking = false`). MetricKit is the hang reporter (`enableMetricKit = true`). The iOS Simulator does not deliver MetricKit diagnostics.

## Prerequisites

- **macOS** with Xcode and an iOS Simulator
- **Homebrew**
- **Git**

The app deploys to iOS 15. Build with Xcode 26.3: the app uses iOS 26 SDK calls, and Xcode 16's SwiftPM can reject Sentry Cocoa's KSCrash dependency. `make test` defaults to an iPhone 17 Pro simulator on the latest installed iOS runtime (`DEVICE_NAME` and `SIMULATOR_OS` override that). The `build` check pins `DEVELOPER_DIR=/Applications/Xcode_26.3.app` on `macos-15`, whose iOS 26.2 runtime has that simulator.

## Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/sentry-demos/ios.git
   cd ios
   ```

2. **Run setup:**

   ```bash
   make setup
   ```

   This command will:

   - Create a `.env` file with placeholder `SENTRY_ORG` and `SENTRY_PROJECT` values, if one is not already there
   - Install Brewfile tools (including `sentry-cli`) and Ruby gems
   - Install pre-commit hooks

   `.env` is gitignored. Do not commit it, an auth token, or a personal environment override. The EmpowerPlant scheme sets `SENTRY_ENVIRONMENT=production`, and the app copies that value onto each event.

3. **Configure Sentry authentication:**

   ```bash
   sentry-cli login
   ```

   Use an **org-level** auth token. Symbol upload reads that token from `SENTRY_AUTH_TOKEN`, `~/.sentryclirc`, or `~/.zshrc`. See the [`sentry-cli` docs](https://docs.sentry.io/product/cli/).

4. **Set the org and project for symbol upload:**

   Edit `.env`:

   ```bash
   SENTRY_ORG=demo
   SENTRY_PROJECT=ios
   ```

   The Xcode build phase **[Sentry] Upload debug symbols** runs `./upload-symbols.sh`. That script reads `SENTRY_ORG` and `SENTRY_PROJECT` from the environment or from `.env`. Test builds skip the upload. `./upload-size-analysis.sh` uses the same two values.

## Running the demo

1. **Open the project in Xcode:**

   ```bash
   open EmpowerPlant.xcodeproj
   ```

2. **Run the app** with the Play button, `⌘R`, or **Product > Run**. The iOS Simulator is enough for the shop. A physical device needs an Apple Developer account.

3. **Walk the shop:**

   - Launch opens the plant list (**Empower Plants**). It loads `GET https://flask.empower-plant.com/products` as it opens. Time to full display ends once that request finishes and the table shows the plants, or once it fails.
   - Each row has **Add to Cart**. Empower’s checkout TDA test taps that button on launch. Do not hide it behind product detail. Product detail also has Add to Cart, plus Water and Repot.
   - The cart icon with the red count badge is on the trailing side of the plant list. The cart lists only plants with a quantity greater than zero. **Checkout** is the trailing button on the cart.
   - Checkout prefills the contact fields. **Apply** fails the promo code. **Place your order** posts to `https://flask.empower-plant.com/checkout` with `validate_inventory` and fails with an inventory error. That error shows a feedback button.
   - The system back chevron is how you leave a screen.

4. **Other issues** is the old Actions menu. It opens from the `ellipsis` button on the leading side of the plant list's navigation bar, with accessibility id `more`. The list rows are:

   - Error
   - NSException
   - Fatal Error
   - DiskWriteException (!)
   - HighCPULoad
   - Permissions (!)
   - Async Crash (!)
   - ANR Fully Blocking
   - ANR Filling Run Loop
   - File I/O on Main Thread

   Fatal Error and Async Crash end the process right after `SentrySDK.flush(timeout: 2)`, so buffered logs are sent before the crash. Repot on product detail does the same. The two ANR rows still block the main thread and record `app.hang` spans. File I/O on Main Thread keeps the app alive and records main-thread `file.write` and `file.read` spans.

## Testing

```bash
make test
```

This runs unit tests on the iOS Simulator and writes a coverage report with Slather.

## Troubleshooting

**CoreSimulator is out of date:**

```bash
xcodebuild -runFirstLaunch
```

**Missing iOS SDK:**

```bash
xcodebuild -downloadPlatform iOS
```

**Build failures:**

- Clean the build folder: `⌘+Shift+K` in Xcode
- Reset package cache: **File > Packages > Reset Package Caches**

**Sentry authentication:**

- The auth token needs permission to upload debug files for the org and project in `.env`
- Run `sentry-cli login` again if the token is missing

### Project structure

```
EmpowerPlant/
├── Main/AppDelegate.swift     # Sentry configuration and the demo DSN
├── UI/                        # Catalog, cart, checkout, Other issues
├── Helpers/                   # Shop telemetry helpers
├── Logic/                     # Shopping cart
├── Models/                    # Core Data product
└── Resources/                 # Storyboard, assets, and catalog copy
```

## Creating releases

The [Release workflow](https://github.com/sentry-demos/ios/actions/workflows/release.yml) builds an unsigned Release device archive and an unsigned Release simulator app. It uploads the device build with the [Sentry Fastlane plugin](https://github.com/getsentry/sentry-fastlane-plugin). On `master` it then publishes a GitHub release with `EmpowerPlant.ipa` and `EmpowerPlant_release.zip`.

It runs every Monday at 00:00 UTC. GitHub only runs that schedule from the default branch (`master`). **Run workflow** starts the same workflow with no inputs.

**Only `master` publishes a GitHub release.** Empower's TDA installs `EmpowerPlant_release.zip` from the first release in the public `/releases` list: the newest one, prereleases included, drafts excluded. A release without that zip, or with a device build in it, stops every iOS TDA run until it is deleted or turned back into a draft. Marking it as a prerelease does not help. A **Run workflow** from any other branch still builds and uploads to Sentry, then keeps `EmpowerPlant.ipa` and `EmpowerPlant_release.zip` as a workflow artifact named `EmpowerPlant-<version>` instead of publishing.

The version name is the UTC date `YY.M.D` (7 October 2026 is `26.10.7`). The build code is `YYMMDD` (`261007`). The workflow writes those into the archive as `CFBundleShortVersionString` and `CFBundleVersion`. It does not commit them. If that GitHub release already exists, the tag becomes `26.10.7-1` and the build code becomes `2610071`. The short version stays `26.10.7`.

There is no Apple distribution certificate in this repository (`CODE_SIGNING_ALLOWED=NO`), so the IPA is unsigned. `build_ios_app` exports a signed IPA, so the `release` lane calls `./deploy_project.sh` for the archive, the IPA, and the simulator zip. That script pins `DEVELOPER_DIR` to Xcode 26.3 and unsets `SDK_V10` before `xcodebuild`. The lane then sends the build to the demo **ios** project. Auth is `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, and `SENTRY_PROJECT`. Leave the token out of the repo.

- **Debug symbols.** `sentry_debug_files_upload` with `include_sources: true` on `EmpowerPlant.xcarchive/dSYMs`, as the [dSYM Fastlane guide](https://docs.sentry.io/platforms/apple/guides/ios/dsym/#sentry-fastlane-plugin) shows. The Xcode build phase also runs during the archive, because the lane passes `SENTRY_ORG`, `SENTRY_PROJECT`, and `SENTRY_AUTH_TOKEN`.
- **Size analysis and build distribution.** One `sentry_upload_build` with `ipa_path`, `dsym_path`, and `build_configuration: "Release"`. The lane also sends the head SHA, head ref, `vcs_provider: github`, and head repo name. When the commit is not `master`, it sends the merge-base with `origin/master` as `base_sha` and `base_ref: master`. Plugin **2.8.0** bundles sentry-cli 3.8.0, which attaches those dSYMs to the IPA upload. See [Size Analysis](https://docs.sentry.io/platforms/apple/guides/ios/size-analysis/) and [Build Distribution](https://docs.sentry.io/platforms/apple/guides/ios/build-distribution/). An unsigned IPA can be uploaded. Installing it on a device still needs an Apple signature, which this repo does not have a secret for.
- **Simulator zip.** `xcodebuild build -configuration Release -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath build`, unsigned, for arm64 and x86_64. `EmpowerPlant_release.zip` holds `build/Build/Products/Release-iphonesimulator/EmpowerPlant.app`, the same layout as release `0.0.44`'s zip. The script unzips it and fails unless the app's `DTPlatformName` is `iphonesimulator`. The lane fails if the zip is missing.
- **GitHub release.** `gh release create` in the workflow, on `master` only. The tag is the version name, on the built commit. The assets are `EmpowerPlant.ipa` and `EmpowerPlant_release.zip`. The workflow fails if either file is missing before the release, or if the published release has no `EmpowerPlant_release.zip`. The Fastlane plugin uploads to Sentry; this step publishes the GitHub release.

`bundle install` installs Fastlane and `fastlane-plugin-sentry` 2.8.0. The same lane locally (it builds and uploads, and the workflow is what publishes the GitHub release):

```bash
bundle install
export SENTRY_ORG=demo
export SENTRY_PROJECT=ios
export SENTRY_AUTH_TOKEN=... # org token, from the environment
bundle exec fastlane ios release marketing_version:26.10.7 build_code:261007 release_tag:26.10.7
```

That needs Xcode 26.3 at `/Applications/Xcode_26.3.app`. Fetch `origin/master` first so the lane can send the base SHA.

The local lane writes `EmpowerPlant_release.zip` at the repository root (gitignored). To install it the way the TDA does, on a booted simulator:

```bash
unzip -q EmpowerPlant_release.zip -d /tmp/empower-zip
xcrun simctl install booted /tmp/empower-zip/build/Build/Products/Release-iphonesimulator/EmpowerPlant.app
xcrun simctl launch booted sentrydemos.ios.EmpowerPlant
```

## TDA

The TDA downloads `https://github.com/sentry-demos/ios/releases/download/<tag>/EmpowerPlant_release.zip` from the newest published release and installs it on a Sauce Labs iPhone 13 simulator (iOS 15.5). See [Creating releases](#creating-releases) for why only `master` publishes.

The error-list test taps the plant list's **more** bar button (accessibility id `more`), then the row titles above.

The checkout test expects **Add to Cart** on launch. The plant list is the first screen, and each row has that button (`AddToCart_<plant title>`). Do not hide it behind product detail.

The command that runs this app in TDA is in [empower `tda/conftest.py`](https://github.com/sentry-demos/empower/blob/a77428aec6cb8e6563caf3d9671419461946db2e/tda/conftest.py#L480-L514).
