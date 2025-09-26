## Overview

An iOS app integrating Sentry to demo its various product features. See [Empower: How to Contribute](https://www.notion.so/sentry/Empower-How-to-Contribute-3190417cf9b14e7c895fb352d5c28bd6#0a64b16867e9418abc027f2450635510) for more information.

## Prerequisites

- **macOS** with Xcode 15.0 or later
- **Homebrew** (will be installed automatically if not present)
- **Git** (for cloning the repository)

## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sentry-demos/ios.git
   cd ios
   ```

2. **Run the automated setup:**
   ```bash
   make init
   ```
   This command will:
   - Install Homebrew (if not already installed)
   - Install required tools via `brew bundle` (sentry-cli, gh)
   - Create a `.env` file with placeholder values
   - Set up Xcode first launch (fixes CoreSimulator issues)
   - Download iOS platform images if needed

3. **Configure Sentry authentication:**
   ```bash
   sentry-cli login
   ```
   Use an **org-level** auth token from your Sentry organization. See [`sentry-cli` docs](https://docs.sentry.io/product/cli/) for more information.

4. **Update environment configuration:**
   Edit the `.env` file and provide valid values:
   ```bash
   SENTRY_ORG=<your-org-slug>
   SENTRY_PROJECT=<your-project-slug>
   ```

   **Default values** (for demo purposes):
   ```
   SENTRY_ORG=demo
   SENTRY_PROJECT=ios
   ```

5. **Optional - Use custom Sentry DSN:**
   If you want to send events to a different org/project than the default, update the DSN in `EmpowerPlant/AppDelegate.swift`:
   ```swift
   options.dsn = "https://your-dsn-here@sentry.io/project-id"
   ```

## Running the App

1. **Open the project in Xcode:**
   ```bash
   open EmpowerPlant.xcodeproj
   ```

2. **Run the app:**
   - Click the "Play" button (▶️) in Xcode, or
   - Press `⌘R`, or
   - Select **Product > Run** from the menu

3. **Choose your target:**
   - **iOS Simulator** (recommended for development)
   - **Physical device** (requires Apple Developer account)

## Testing

Run the test suite:
```bash
make test
```

This will:
- Run unit tests on the latest iOS Simulator
- Generate code coverage reports using Slather

## Troubleshooting

### Common Issues

**CoreSimulator out of date error:**
```bash
make init  # This runs xcodebuild -runFirstLaunch to fix the issue
```

**Missing iOS SDK:**
```bash
xcodebuild -downloadPlatform iOS
```

**Build failures:**
- Ensure you have the latest Xcode version
- Clean build folder: `⌘+Shift+K` in Xcode
- Reset package cache: `File > Packages > Reset Package Caches`

**Sentry authentication issues:**
- Verify your auth token has the correct permissions
- Check that your org/project slugs in `.env` match your Sentry setup
- Run `sentry-cli login` again if needed

### Project Structure

```
EmpowerPlant/
├── AppDelegate.swift          # Sentry configuration
├── Views/                     # UI Controllers
├── Models/                    # Core Data models
├── Helpers/                   # Utility classes
└── Resources/                 # Assets and data files
```

## Creating Releases

### Prerequisites
- Ensure `Info.plist` has the correct version number
- Commit changes to the `master` branch (recommended)

### Release Process

1. **Go to GitHub Actions:**
   - Navigate to the repo's [Actions](https://github.com/sentry-demos/ios/actions) page
   - Find the [Release workflow](https://github.com/sentry-demos/ios/actions/workflows/release.yml)

2. **Trigger the release:**
   - Click "Run workflow" dropdown
   - Enter the version number (e.g., `0.0.43`)
   - Click "Run workflow" to start the build

3. **What happens:**
   - Builds the iOS app with the specified version
   - Uploads debug symbols to Sentry
   - Creates a GitHub release with the app binary
   - Uses configured secrets for authentication

**Note:** TDA (Test Data Automation) must be restarted to pick up new versions.

See [sample release](https://github.com/sentry-demos/ios/releases/tag/0.0.1) for reference.

## TDA

The command that runs this in TDA can be found here: https://github.com/sentry-demos/empower/blob/a77428aec6cb8e6563caf3d9671419461946db2e/tda/conftest.py#L480-L514
