.PHONY: init
init:
	# ensure Homebrew is installed
	which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# set up dev tools
	brew bundle

	# set up ruby environment
	rbenv install --skip-existing
	rbenv exec gem update bundler
	rbenv exec bundle update

	# install app dependencies via CocoaPods
	rbenv exec bundle exec pod update

	# ensure there's a .env file present
	stat .env 2>/dev/null || echo "SENTRY_ORG=<your org slug>\nSENTRY_PROJECT=<your project slug>" > .env

	# fixes CoreSimulator out of date error 
	# (happens on fresh xcode installation or MAS-managed major version update)
	# requires password when run without sudo
	xcodebuild -runFirstLaunch

	# download iOS platform image
	# (happens on fresh xcode installation or MAS-managed major version update)
	xcodebuild -downloadPlatform iOS

release:
	xcodebuild -workspace EmpowerPlant.xcworkspace -scheme EmpowerPlant -configuration Release -derivedDataPath build -sdk iphonesimulator clean build 2>&1 | tee release-build.log | xcbeautify
	zip -r EmpowerPlant_release.zip ./build/Build/Products/Release-iphonesimulator/EmpowerPlant.app
	@echo "\nBuild completed. Create a new release in GitHub and upload ./EmpowerPlant_release.zip."
