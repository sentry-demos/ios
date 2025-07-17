.PHONY: init
init:
	# ensure Homebrew is installed
	which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# set up dev tools
	brew bundle

	# ensure there's a .env file present
	stat .env 2>/dev/null || echo "SENTRY_ORG=<your org slug>\nSENTRY_PROJECT=<your project slug>" > .env

	# perform first launch operations if needed. fixes CoreSimulator out of date error 
	# (happens on fresh xcode installation or MAS-managed major version update)
	# requires password when run without sudo
	xcodebuild -checkFirstLaunchStatus || xcodebuild -runFirstLaunch

	# download iOS platform image if needed
	# (happens on fresh xcode installation or MAS-managed major version update)
	xcodebuild -showsdks | grep -q "iOS.*-sdk iphoneos" || xcodebuild -downloadPlatform iOS

.PHONY: test
test:
	xcodebuild -project EmpowerPlant.xcodeproj -scheme EmpowerPlant -configuration Test -derivedDataPath build -destination "platform=iOS Simulator,OS=latest,name=iPhone 15" -quiet test
	slather coverage --configuration Test --verbose
