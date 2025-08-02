APP_NAME = macos-snipper
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)

.PHONY: build bundle dmg clean

build:
	swift build --arch x86_64 -c release

bundle: build
	@echo "Creating app bundle..."
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/
	chmod +x $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@echo "App bundle created at $(APP_BUNDLE)"

dmg: bundle
	hdiutil create -volname "$(APP_NAME)" -srcfolder $(APP_BUNDLE) -ov -format UDZO $(APP_NAME).dmg
	@echo "DMG created: $(APP_NAME).dmg"

clean:
	rm -rf .build $(APP_NAME).dmg
