#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/.build/xcode/Build/Products/Release/Endpoint Mapper.app"
[[ -d "$APP" ]] || { echo 'Execute build-app.sh primeiro.' >&2; exit 1; }
STAGING="$(mktemp -d "$ROOT/.build/dmg-stage.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$ROOT/dist"
ditto "$APP" "$STAGING/Endpoint Mapper.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname 'Endpoint Mapper' -srcfolder "$STAGING" -ov -format UDZO "$ROOT/dist/EndpointMapper.dmg"
hdiutil verify "$ROOT/dist/EndpointMapper.dmg"
