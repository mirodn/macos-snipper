# Makefile

APP_NAME       = macos-snipper
CONFIG        ?= release
DIST_DIR       = dist
APP_BUNDLE     = $(DIST_DIR)/$(APP_NAME).app
RESOURCES_DIR  = Resources
DMG_SRC_DIR    = $(DIST_DIR)/dmg-root   # Temporary folder for DMG contents

# UNIVERSAL=1 → Builds a universal binary (arm64 + x86_64)
# Without UNIVERSAL → Builds only for the host architecture

.PHONY: build build-universal bundle sign dmg dmg-nobrew clean

# Native Build (host architecture only)
build:
	@set -euxo pipefail; \
	swift build -c $(CONFIG) -v

# Universal Build (arm64 + x86_64, merged with lipo)
build-universal:
	@set -euxo pipefail; \
	swift build -c $(CONFIG) --arch arm64 -v; \
	swift build -c $(CONFIG) --arch x86_64 -v; \
	OUT_ARM="$$(swift build -c $(CONFIG) --arch arm64 --show-bin-path)"; \
	OUT_X86="$$(swift build -c $(CONFIG) --arch x86_64 --show-bin-path)"; \
	BIN_ARM="$$OUT_ARM/$(APP_NAME)"; \
	BIN_X86="$$OUT_X86/$(APP_NAME)"; \
	ls -lah "$$BIN_ARM" "$$BIN_X86"; \
	mkdir -p "$(DIST_DIR)"; \
	lipo -create "$$BIN_ARM" "$$BIN_X86" -output "$(DIST_DIR)/$(APP_NAME)"; \
	file "$(DIST_DIR)/$(APP_NAME)"

# Create the .app bundle
bundle: $(if $(UNIVERSAL),build-universal,build)
	@set -euxo pipefail; \
	rm -rf "$(APP_BUNDLE)"; \
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"; \
	cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"; \
	if [ "$(UNIVERSAL)" = "1" ]; then \
	  SRC_BIN="$(DIST_DIR)/$(APP_NAME)"; \
	else \
	  BIN_DIR="$$(swift build -c $(CONFIG) --show-bin-path)"; \
	  SRC_BIN="$$BIN_DIR/$(APP_NAME)"; \
	fi; \
	cp "$$SRC_BIN" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"; \
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"; \
	if [ -f "$(RESOURCES_DIR)/AppIcon.icns" ]; then \
	  cp "$(RESOURCES_DIR)/AppIcon.icns" "$(APP_BUNDLE)/Contents/Resources/"; \
	fi; \
	echo "Bundle created: $(APP_BUNDLE)"; \
	file "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"

# Ad-hoc sign the .app bundle (no keychain or notarization)
sign: bundle
	@set -euxo pipefail; \
	codesign --force --deep --sign - --timestamp=none "$(APP_BUNDLE)"; \
	codesign -dv --verbose=4 "$(APP_BUNDLE)" || true

# Create DMG with create-dmg (only includes the .app bundle)
dmg: sign
	@set -euxo pipefail; \
	rm -rf "$(DMG_SRC_DIR)"; \
	mkdir -p "$(DMG_SRC_DIR)"; \
	cp -R "$(APP_BUNDLE)" "$(DMG_SRC_DIR)/$(APP_NAME).app"; \
	create-dmg \
	  --volname "$(APP_NAME)" \
	  $(if $(wildcard $(RESOURCES_DIR)/AppIcon.icns),--volicon "$(RESOURCES_DIR)/AppIcon.icns",) \
	  --window-pos 200 120 \
	  --window-size 600 400 \
	  --icon-size 100 \
	  $(if $(wildcard assets/dmg-background.png),--background "assets/dmg-background.png",) \
	  --icon "$(APP_NAME).app" 150 200 \
	  --app-drop-link 450 200 \
	  "$(APP_NAME).dmg" \
	  "$(DMG_SRC_DIR)"; \
	ls -lah "$(APP_NAME).dmg"

# Create DMG without Homebrew (using hdiutil)
dmg-nobrew: sign
	@set -euxo pipefail; \
	rm -rf "$(DMG_SRC_DIR)"; \
	mkdir -p "$(DMG_SRC_DIR)"; \
	cp -R "$(APP_BUNDLE)" "$(DMG_SRC_DIR)/$(APP_NAME).app"; \
	rm -f "$(APP_NAME).dmg"; \
	hdiutil create -volname "$(APP_NAME)" -srcfolder "$(DMG_SRC_DIR)" -ov -format UDZO "$(APP_NAME).dmg"; \
	ls -lah "$(APP_NAME).dmg"

# Clean build artifacts and generated DMGs
clean:
	rm -rf .build "$(DIST_DIR)" *.dmg
