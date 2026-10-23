#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="$ROOT/branding/app-icon/rounded-master.png"
DEST="$ROOT/macos/Resources/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 128 256 512; do
  for scale in 1 2; do
    pixels=$((size * scale))
    sips -z "$pixels" "$pixels" "$SOURCE" --out "$DEST/icon_${size}x${size}@${scale}x.png" >/dev/null
  done
done
