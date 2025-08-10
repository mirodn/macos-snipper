# Makefile

APP_NAME      = macos-snipper
CONFIG       ?= release
DIST_DIR      = dist
APP_BUNDLE    = $(DIST_DIR)/$(APP_NAME).app
RESOURCES_DIR = Resources

# UNIVERSAL=1  -> baut arm64 + x86_64 und lipo't sie zusammen
# sonst: native Arch (auf Intel: x86_64, auf Apple Silicon: arm64)

.PHONY: build build-universal bundle sign dmg clean

# Native Build (keine Arch-Angabe -> Compiler nimmt Host-Arch)
build:
	@set -euxo pipefail; \
	swift build -c $(CONFIG) -v

# Universal Build (nur wenn UNIVERSAL=1 gesetzt)
build-universal:
	@set -euxo pipefail; \
	OUT_ARM="$$(swift build -c $(CONFIG) --arch arm64 --show-bin-path)"; \
	OUT_X86="$$(swift build -c $(CONFIG) --arch x86_64 --show-bin-path)"; \
	BIN_ARM="$$OUT_ARM/$(APP_NAME)"; \
	BIN_X86="$$OUT_X86/$(APP_NAME)"; \
	mkdir -p "$(DIST_DIR)"; \
	lipo -create "$$BIN_ARM" "$$BIN_X86" -output "$(DIST_DIR)/$(APP_NAME)"; \
	file "$(DIST_DIR)/$(APP_NAME)"

# Wählt je nach UNIVERSAL den richtigen Build & Executable
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
	echo "Bundle: $(APP_BUNDLE)"; \
	file "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"

# Ad-hoc Signatur (kein Keychain/Netz)
sign: bundle
	@set -euxo pipefail; \
	codesign --force --deep --sign - --timestamp=none "$(APP_BUNDLE)"; \
	codesign -dv --verbose=4 "$(APP_BUNDLE)" || true

# DMG mit create-dmg
dmg: sign
	@set -euxo pipefail; \
	mkdir -p "$(DIST_DIR)"; \
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
	  "$(DIST_DIR)"; \
	ls -lah "$(APP_NAME).dmg"

clean:
	rm -rf .build "$(DIST_DIR)" *.dmg
