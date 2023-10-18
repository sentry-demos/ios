.PHONY: init
init:
	# ensure Homebrew is installed
	which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# set up dev tools
	brew bundle

	# ensure there's a .env file present
	stat .env 2>/dev/null || echo "SENTRY_ORG=<your org slug>\nSENTRY_PROJECT=<your project slug>" > .env

	# fixes CoreSimulator out of date error 
	# (happens on fresh xcode installation or MAS-managed major version update)
	# requires password when run without sudo
	xcodebuild -runFirstLaunch

	# download iOS platform image
	# (happens on fresh xcode installation or MAS-managed major version update)
	xcodebuild -downloadPlatform iOS
