#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="${1:?Informe o diretório Resources/engine}"
[[ -f "$ROOT/engine/dist/protocol/server.js" ]] || { echo 'Execute npm run build --prefix engine antes de compilar.' >&2; exit 1; }
mkdir -p "$DEST/node_modules/ignore"
ditto "$ROOT/engine/dist" "$DEST"
printf '%s\n' '{"type":"module","private":true}' > "$DEST/package.json"
ditto "$ROOT/engine/node_modules/ignore" "$DEST/node_modules/ignore"
# The standalone Phase 0 server has been replaced by compiled modules.
rm -f "$DEST/server.ts"
