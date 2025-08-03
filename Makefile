APP_NAME = macos-snipper
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)

.PHONY: build bundle dmg clean sign

build:
	swift build --arch x86_64 -c release

bundle: build
	@echo "Creating app bundle..."
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/
	chmod +x $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@if [ -f "AppIcon.icns" ]; then cp AppIcon.icns $(APP_BUNDLE)/Contents/Resources/; fi
	@echo "✅ App bundle created at $(APP_BUNDLE)"

sign: bundle
	@echo "Signing app for local use..."
	codesign --force --deep --sign - $(APP_BUNDLE)

dmg: sign
	@echo "Creating DMG..."
	create-dmg \
		--volname "$(APP_NAME)" \
		--volicon "AppIcon.icns" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--background "assets/dmg-background.png" \
		--icon "$(APP_NAME).app" 150 200 \
		--app-drop-link 450 200 \
		"$(APP_NAME).dmg" \
		"$(BUILD_DIR)"
	@echo "DMG created: $(APP_NAME).dmg"

clean:
	rm -rf .build $(APP_NAME).dmg
