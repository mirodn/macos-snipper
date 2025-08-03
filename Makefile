APP_NAME = macos-snipper
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)
RESOURCES_DIR = Resources

.PHONY: build bundle dmg clean sign

# Build the executable
build:
	swift build --arch x86_64 -c release

# Create .app bundle structure
bundle: build
	@echo "Creating app bundle..."
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/
	chmod +x $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@if [ -f "$(RESOURCES_DIR)/AppIcon.icns" ]; then \
		cp $(RESOURCES_DIR)/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/; \
		echo "Added AppIcon.icns"; \
	else \
		echo "No AppIcon.icns found, skipping..."; \
	fi
	@echo "App bundle created at $(APP_BUNDLE)"

# Ad-hoc signing (for local test, not for App Store)
sign: bundle
	@echo "🔏 Signing app for local use..."
	codesign --force --deep --sign - $(APP_BUNDLE)

# Create DMG (requires create-dmg: brew install create-dmg)
dmg: sign
	@if ! command -v create-dmg >/dev/null 2>&1; then \
		echo "create-dmg not installed. Install with: brew install create-dmg"; \
		exit 1; \
	fi
	@echo "Creating DMG..."
	create-dmg \
		--volname "$(APP_NAME)" \
		--volicon "$(RESOURCES_DIR)/AppIcon.icns" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		$(if $(wildcard assets/dmg-background.png),--background "assets/dmg-background.png",) \
		--icon "$(APP_NAME).app" 150 200 \
		--app-drop-link 450 200 \
		"$(APP_NAME).dmg" \
		"$(BUILD_DIR)"
	@echo "DMG created: $(APP_NAME).dmg"

clean:
	rm -rf .build $(APP_NAME).dmg
