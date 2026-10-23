#!/bin/bash
set -euo pipefail
APP="${1:?Informe o caminho do aplicativo}"
codesign --verify --deep --strict "$APP"
for weight in Regular Medium SemiBold Bold; do
  [[ -s "$APP/Contents/Resources/Fonts/JetBrainsMono-$weight.ttf" ]]
done
[[ -s "$APP/Contents/Resources/Fonts/OFL.txt" ]]
[[ -s "$APP/Contents/Resources/Node-LICENSE.txt" ]]
[[ -s "$APP/Contents/Resources/Branding/logo.png" ]]
[[ -s "$APP/Contents/Resources/AppIcon.icns" ]]
[[ -s "$APP/Contents/Resources/engine/protocol/server.js" ]]
[[ -s "$APP/Contents/Resources/engine/node_modules/ignore/LICENSE-MIT" ]]
printf '%s\n' '{"jsonrpc":"2.0","id":"bundle-check","method":"initialize","params":{"protocolVersion":1}}' | env -i PATH=/usr/bin:/bin "$APP/Contents/Helpers/node" "$APP/Contents/Resources/engine/protocol/server.js"
