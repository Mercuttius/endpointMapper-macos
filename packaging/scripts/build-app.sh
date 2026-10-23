#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NODE="${NODE_BINARY:-$(command -v node)}"
NODE_LICENSE="${NODE_LICENSE_FILE:-$(dirname "$(dirname "$NODE")")/LICENSE}"
[[ -f "$NODE_LICENSE" ]] || { echo 'Informe NODE_LICENSE_FILE com a licença do runtime.' >&2; exit 1; }
[[ "$("$NODE" --version)" == v24.* ]] || { echo 'Este build requer Node 24.' >&2; exit 1; }
HOST_ARCH="$(uname -m)"
RUNTIME_ARCH="$("$NODE" -p process.arch)"
if [[ "$HOST_ARCH:$RUNTIME_ARCH" != "x86_64:x64" && "$HOST_ARCH:$RUNTIME_ARCH" != "arm64:arm64" ]]; then
  echo 'O runtime deve corresponder à arquitetura do Mac de build.' >&2; exit 1
fi
mkdir -p "$ROOT/.build/runtime"
cp "$NODE" "$ROOT/.build/runtime/node"
cp "$NODE_LICENSE" "$ROOT/.build/runtime/Node-LICENSE.txt"
npm run build --prefix "$ROOT/engine"
xcodebuild -project "$ROOT/macos/EndpointMapper.xcodeproj" -scheme EndpointMapper -configuration Release -derivedDataPath "$ROOT/.build/xcode" build
APP="$ROOT/.build/xcode/Build/Products/Release/Endpoint Mapper.app"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf 'Aplicativo criado: %s\n' "$APP"
