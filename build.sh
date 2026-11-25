#!/bin/bash
# Builds the local app without installing or launching it.
set -euo pipefail
cd "$(dirname "$0")"

xcodegen generate --quiet
xcodebuild -project SnelWachtwoord.xcodeproj -scheme SnelWachtwoord -configuration Release \
  -destination generic/platform=macOS -derivedDataPath build/DerivedData -quiet "$@" build
APP=build/DerivedData/Build/Products/Release/SnelWachtwoord.app
printf '%s\n' "$PWD/$APP"
