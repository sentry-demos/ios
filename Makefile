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

release:
	CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO xcodebuild -workspace EmpowerPlant.xcworkspace -scheme EmpowerPlant -configuration Release -derivedDataPath build -sdk iphoneos clean build 2>&1 | tee release-build.log | xcbeautify
