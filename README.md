## Overview

Empower Plants is an iOS shop that demos Sentry. The app uses the Sentry Cocoa SDK **9.30.0** (`SentrySPM`, `import SentrySwift`).

The DSN in `EmpowerPlant/Main/AppDelegate.swift` sends events to the demo organization, project **ios**. A commented wassim-test DSN sits above `options.dsn` so that project can be restored. Leave the active DSN on the demo ios project.

Sentry's app-hang watcher is off (`enableAppHangTracking = false`). MetricKit is the hang reporter (`enableMetricKit = true`). The iOS Simulator does not deliver MetricKit diagnostics.

## Prerequisites

- **macOS** with Xcode and an iOS Simulator
- **Homebrew**
- **Git**

The app deploys to iOS 15. `make test` defaults to an iPhone 17 Pro simulator (`DEVICE_NAME` and `SIMULATOR_OS` override that).

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

   - Launch opens the home screen: the succulent photo, the title **Empower Plants**, **Other issues**, and **View products** (`ViewProducts`).
   - **View products** opens the plant catalog. `GET https://flask.empower-plant.com/products` runs when that screen loads, not at launch.
   - Each catalog row has **Add to Cart**. Empower’s checkout TDA test still expects that button on launch, because the plant list used to be the first screen. Do not hide it behind product detail. Product detail also has Add to Cart, plus Water and Repot.
   - The cart icon with the red count badge is on the trailing side of the plant list. The cart lists only plants with a quantity greater than zero. **Checkout** is the trailing button on the cart.
   - Checkout prefills the contact fields. **Apply** fails the promo code. **Place your order** posts to `https://flask.empower-plant.com/checkout` with `validate_inventory` and fails with an inventory error. That error shows a feedback button.
   - The system back chevron is how you leave a screen. There is no Home bar button and no overflow menu.

4. **Other issues** is the old Actions menu. The button is on the home screen only, with accessibility id `more`. It is not in the navigation bar. The list rows are:

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

   Fatal Error and Async Crash end the process immediately. The two ANR rows still block the main thread and record `app.hang` spans. File I/O on Main Thread keeps the app alive and records main-thread `file.write` and `file.read` spans.

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
├── UI/                        # Home, catalog, cart, checkout, Other issues
├── Helpers/                   # Shop telemetry helpers
├── Logic/                     # Shopping cart
├── Models/                    # Core Data product
└── Resources/                 # Storyboard, assets, and catalog copy
```

## Creating releases

The [Release workflow](https://github.com/sentry-demos/ios/actions/workflows/release.yml) builds one unsigned Release archive, uploads that build, then publishes `EmpowerPlant.ipa` from the archive.

It runs every Monday at 00:00 UTC. GitHub only runs that schedule from the default branch (`master`). **Run workflow** starts the same workflow with no inputs.

The version name is the UTC date `YY.M.D` (7 October 2026 is `26.10.7`). The build code is `YYMMDD` (`261007`). The workflow writes those into the archive as `CFBundleShortVersionString` and `CFBundleVersion`. It does not commit them. If that GitHub release already exists, the tag becomes `26.10.7-1` and the build code becomes `2610071`. The short version stays `26.10.7`.

There is no Apple distribution certificate in this repository (`CODE_SIGNING_ALLOWED=NO`), so the IPA is unsigned. The workflow sends that build to the demo **ios** project, then creates the GitHub release:

- **Debug symbols.** `sentry-cli upload-dif --include-sources` on `EmpowerPlant.xcarchive/dSYMs`. This is the same command as `upload-symbols.sh`. The Xcode build phase also runs during the archive, because the workflow passes `SENTRY_ORG`, `SENTRY_PROJECT`, and `SENTRY_AUTH_TOKEN`.
- **Size analysis.** `sentry-cli build upload EmpowerPlant.ipa` with `--build-configuration Release`, `--head-sha`, `--head-ref`, `--vcs-provider github`, and `--head-repo-name`. When the commit is not `master`, it also sends the merge-base as `--base-sha` and `--base-ref master`. `--dsym` points at the archive dSYMs so the IPA upload still has symbols. The Flutter [size analysis guide](https://github.com/sentry-demos/flutter/blob/main/SIZE_ANALYSIS_GUIDE.md) uses this command.
- **Build distribution.** The same `sentry-cli build upload`. The Flutter demo uses that one command for size analysis and build distribution. No extra secret. Auth is the existing `SENTRY_AUTH_TOKEN`, with `SENTRY_ORG` and `SENTRY_PROJECT`. The release workflow installs sentry-cli **3.8.0** so `--dsym` is available. An unsigned IPA can be uploaded. Installing it on a device still needs an Apple signature, which this repo does not have a secret for.
- **GitHub release.** The tag is the version name. The only asset is `EmpowerPlant.ipa`.

Sauce Labs TDA still downloads `EmpowerPlant_release.zip` (a simulator `.app`). This workflow no longer publishes that zip. See an older [sample release](https://github.com/sentry-demos/ios/releases/tag/0.0.1).

## TDA

The error-list test should use the home-screen **Other issues** button (accessibility id `more`), then the row titles above. That used to be a **more** bar button that opened an Actions menu.

The checkout test still expects **Add to Cart** on launch. The plant list used to be the first screen, and each row still has that button. Do not hide it behind product detail.

The command that runs this app in TDA is in [empower `tda/conftest.py`](https://github.com/sentry-demos/empower/blob/a77428aec6cb8e6563caf3d9671419461946db2e/tda/conftest.py#L480-L514).
