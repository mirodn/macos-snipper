# Makefile

APP_NAME       = macos-snipper
CONFIG        ?= release
DIST_DIR       = dist
APP_BUNDLE     = $(DIST_DIR)/$(APP_NAME).app
RESOURCES_DIR  = Resources
DMG_SRC_DIR    = $(DIST_DIR)/dmg-root   # Temporary folder for DMG contents

# Install-Ziel (lokales Test-Bundle)
APP_INSTALL_DIR     ?= $(HOME)/Applications
APP_INSTALL_BUNDLE   = $(APP_INSTALL_DIR)/$(APP_NAME).app

# UNIVERSAL=1 → Builds a universal binary (arm64 + x86_64)
# Without UNIVERSAL → Builds only for the host architecture

.PHONY: build build-universal bundle sign dmg dmg-nobrew clean \
        local-app install-local run-local open-privacy uninstall-local show-app tcc-reset bundle-id

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
	xattr -rc "$(APP_BUNDLE)"; \
	find "$(APP_BUNDLE)" -name '._*' -delete -o -name '.DS_Store' -delete; \
	# plutil -convert xml1 "$(APP_BUNDLE)/Contents/Info.plist"; \
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

# ------------------------------
#           NEW TARGETS
# ------------------------------

# Build+Bundle+Sign → in ~/Applications installieren (lokal testen wie Release)
local-app: sign
	@set -euxo pipefail; \
	mkdir -p "$(APP_INSTALL_DIR)"; \
	rm -rf "$(APP_INSTALL_BUNDLE)"; \
	cp -R "$(APP_BUNDLE)" "$(APP_INSTALL_BUNDLE)"; \
	# ad-hoc re-sign (nach Kopie, für TCC ist das sauberer)
	codesign --force --deep --sign - --timestamp=none "$(APP_INSTALL_BUNDLE)"; \
	echo "Installed: $(APP_INSTALL_BUNDLE)"; \
	file "$(APP_INSTALL_BUNDLE)/Contents/MacOS/$(APP_NAME)"

# Installieren und starten
run-local: local-app
	open "$(APP_INSTALL_BUNDLE)"

# Finder auf die installierte App fokussieren
show-app:
	open -R "$(APP_INSTALL_BUNDLE)"

# Privacy-Panels öffnen (Screen Recording + Input Monitoring)
open-privacy:
	open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"; \
	open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"

# Bundle-ID ermitteln (aus installiertem Bundle)
bundle-id:
	@/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$(APP_INSTALL_BUNDLE)/Contents/Info.plist"

# TCC-Einträge für die installierte App zurücksetzen (sudo erforderlich)
tcc-reset:
	@set -euxo pipefail; \
	BPLIST="$(APP_INSTALL_BUNDLE)/Contents/Info.plist"; \
	BID="$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$$BPLIST")"; \
	echo "Reset TCC for $$BID"; \
	sudo tccutil reset ScreenCapture "$$BID" || true; \
	sudo tccutil reset ListenEvent "$$BID" || true; \
	sudo tccutil reset Accessibility "$$BID" || true

# Deinstallation der lokalen Test-App
uninstall-local:
	rm -rf "$(APP_INSTALL_BUNDLE)"
