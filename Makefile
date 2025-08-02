APP_NAME = macos-snipper
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

.PHONY: build bundle dmg clean

build:
	swift build -c release

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/

dmg: bundle
	hdiutil create -volname "$(APP_NAME)" -srcfolder $(APP_BUNDLE) -ov -format UDZO $(APP_NAME).dmg
	@echo "✅ DMG created: $(APP_NAME).dmg"

clean:
	rm -rf .build $(APP_NAME).dmg
