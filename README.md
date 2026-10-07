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

   `.env` is gitignored. Do not commit it, a `wassim-local` environment, or an auth token.

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
   - Each catalog row has **Add to Cart** immediately. Empower TDA's checkout test still expects that button on the list. Opening a plant is optional; product detail also has Add to Cart, plus Water and Repot.
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

   Fatal Error and Async Crash flush for 2 seconds before they crash. The two ANR rows still block the main thread and record `app.hang` spans. File I/O on Main Thread stays on the main thread and finishes its own transaction. The `file.write` and `file.read` spans set `blocked_main_thread` and `file.size`, which is what Sentry uses for the File I/O on Main Thread performance issue. Background the app after the tap so that transaction can send.

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

### Prerequisites

- `Info.plist` has the version number you want to ship
- Commit the release changes on `master` (recommended)

### Release process

1. **Go to GitHub Actions:**
   - Open the repo's [Actions](https://github.com/sentry-demos/ios/actions) page
   - Open the [Release workflow](https://github.com/sentry-demos/ios/actions/workflows/release.yml)

2. **Trigger the release:**
   - Click **Run workflow**
   - Enter the version number (for example `0.0.43`)
   - Click **Run workflow**

3. **What happens:**
   - Builds the iOS app at that version
   - Uploads debug symbols to Sentry
   - Creates a GitHub release with the app binary
   - Uses the repository secrets for authentication

TDA must be restarted to pick up a new version. See a [sample release](https://github.com/sentry-demos/ios/releases/tag/0.0.1).

## TDA

The error-list test starts from **Other issues** (accessibility id `more`) on the home screen, then taps the row titles above. That used to be a **more** bar button that opened an Actions menu.

The checkout test still expects **Add to Cart** on the plant list as soon as that screen is visible. Do not hide it behind product detail.

The command that runs this app in TDA is in [empower `tda/conftest.py`](https://github.com/sentry-demos/empower/blob/a77428aec6cb8e6563caf3d9671419461946db2e/tda/conftest.py#L480-L514).
