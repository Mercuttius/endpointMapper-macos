#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NODE="${NODE_BINARY:-$(command -v node)}"
BUNDLE="$ROOT/.build/EndpointMapper Bridge Probe.app"
mkdir -p "$BUNDLE/Contents/"{MacOS,Helpers,Resources/engine} "$ROOT/.build/module-cache"
cp "$NODE" "$BUNDLE/Contents/Helpers/node"
npm run build --prefix "$ROOT/engine"
bash "$ROOT/packaging/scripts/embed-engine.sh" "$BUNDLE/Contents/Resources/engine"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.endpointmapper.bridge-probe</string>
<key>CFBundleExecutable</key><string>BridgeProbe</string>
<key>CFBundleName</key><string>EndpointMapper Bridge Probe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
swiftc -module-cache-path "$ROOT/.build/module-cache" -target "$(uname -m)-apple-macosx14.0" "$ROOT/macos/AnalysisBridge/BridgeProbe.swift" -o "$BUNDLE/Contents/MacOS/BridgeProbe"
env -i PATH=/usr/bin:/bin "$BUNDLE/Contents/MacOS/BridgeProbe"
