#!/bin/zsh
# Builds "Logo Light.app" into build/.
#   ./build.sh            the real app
#   ./build.sh --preview  fake backend, safe to run: no password, no system change
set -euo pipefail
cd "$(dirname "$0")"

app="build/Logo Light.app"
flags=()
if [[ "${1:-}" == "--preview" ]]; then
    app="build/Logo Light Preview.app"
    flags=(-D PREVIEW)
fi

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macos14.0 \
    ${flags[@]} Sources/*.swift -o "$app/Contents/MacOS/LogoLight"

if [[ ! -f build/AppIcon.icns ]]; then
    swift Tools/make_icon.swift build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
    rm -rf build/AppIcon.iconset
fi

cp Resources/Info.plist "$app/Contents/Info.plist"
cp build/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
if [[ -n "${flags[*]:-}" ]]; then
    plutil -replace CFBundleIdentifier -string local.LogoLight.preview "$app/Contents/Info.plist"
fi

codesign --force --sign - "$app"
echo "Built $app"
