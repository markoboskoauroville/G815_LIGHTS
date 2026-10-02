#!/bin/sh
# build.sh: G815 Lights.app (the app, the only face) and build/g815 (the same wire as a command line, for tests).
# swiftc straight, no Xcode. The version is VERSION in app/Views.swift; it is written into the bundle too.
set -e
cd "$(dirname "$0")"
mkdir -p build
WIRE="src/hidpp.swift src/lights.swift src/onboard.swift"
swiftc -O -swift-version 5 -o build/g815 $WIRE src/serve.swift src/main.swift
V=$(sed -n 's/^let VERSION = \([0-9]*\)/\1/p' app/Views.swift)
APP="build/G815 Lights.app"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 -o "$APP/Contents/MacOS/G815Lights" $WIRE app/*.swift 2>&1 | grep -v "warning:" || true
[ -x "$APP/Contents/MacOS/G815Lights" ] || { echo "the app did not build"; exit 1; }
cp layout.json "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>G815 Lights</string>
<key>CFBundleDisplayName</key><string>G815 Lights</string>
<key>CFBundleIdentifier</key><string>community.auroville.g815lights</string>
<key>CFBundleExecutable</key><string>G815Lights</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$V</string>
<key>CFBundleVersion</key><string>$V</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PL
# ad hoc, but with a designated requirement that names the bundle, not this build's hash: macOS keeps
# the Input Monitoring permission across rebuilds instead of asking again every time
codesign --force -s - -r='designated => identifier "community.auroville.g815lights"' "$APP" >/dev/null 2>&1
echo "built build/g815 and $APP (v$V)"
