# Fundação nativa — Fase 1

Implementação: projeto Xcode com targets EndpointMapper e EndpointMapperTests; SwiftUI em janelas AppKit; splash antes da janela principal; verificação assíncrona do helper; recuperação de erro; tema GitHub Dark; fontes JetBrains Mono 2.304 incorporadas com OFL; branding original e AppIcon; três painéis; seletor nativo e drag-and-drop de pasta; inspector; preferências de escala; About e licenças.

As seções Endpoints/Mapa/Diagnósticos são estados informativos, sem simulações. Selecionar uma pasta não analisa seu conteúdo. Projetos recentes e SQLite ficam para implementação posterior.

## Compilar

```sh
bash packaging/scripts/build-app.sh
```

Runtime de desenvolvimento: Node 24. O script copia o executável e sua licença para .build/runtime antes de chamar Xcode. Para um runtime de outra origem, informar NODE_BINARY e NODE_LICENSE_FILE. Depois do primeiro preparo, o projeto macos/EndpointMapper.xcodeproj pode ser aberto diretamente no Xcode. O bundle final usa apenas caminhos relativos internos.

```sh
xcodebuild -project macos/EndpointMapper.xcodeproj -scheme EndpointMapper -destination 'platform=macOS' -derivedDataPath .build/xcode test
bash packaging/scripts/build-dmg.sh
```

O gerador packaging/scripts/generate-project.py mantém configurações determinísticas e não exige ferramentas de terceiros. Gerar novamente apenas ao alterar estrutura/configuração. Os ícones são escalas proporcionais da imagem original, sem redesenho.

## Limites

Sem análise de endpoints, transporte persistente, cache, persistência de projetos ou distribuição pública notarizada. O handshake é executado fora do MainActor com timeout, mas não substitui a sessão com streaming/cancelamento da Fase 2. Ainda é necessário verificar navegação/VoiceOver em sessão interativa, aparência do Finder/DMG, execução em macOS 14 e Apple Silicon. Os controles gerenciados pelo sistema podem usar a tipografia do macOS.

## Verificação de bundle

```sh
bash packaging/scripts/verify-bundle.sh '.build/xcode/Build/Products/Release/Endpoint Mapper.app'
```

O build usa somente a arquitetura do host e recusa runtime incompatível. O helper recebe assinatura ad hoc antes de o Xcode assinar o aplicativo. Não é assinatura Developer ID nem notarização. O DMG inicial contém o app e o atalho Applications; personalização visual da janela do Finder ainda está pendente.
