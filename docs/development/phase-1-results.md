# Resultados — Fundação nativa

19/10/2026; host Intel x86_64, Xcode 26.2, Swift 6.2.3, Node 24.19.0.

## Entregue

- Projeto Xcode real, esquema compartilhado e targets de testes.
- Aplicativo SwiftUI/AppKit com splash anterior à janela principal, handshake assíncrono e recuperação de falha.
- Logo original, AppIcon, tema GitHub Dark e quatro pesos JetBrains Mono 2.304 com licença.
- Sidebar, área central, inspector, toolbar, seleção nativa/arraste de pasta, Settings e About.
- Build local autocontido com Node interno, licenças e assinatura ad hoc.
- Scripts de build, verificação de bundle e DMG.

## Verificado

- Build Debug e Release: passaram.
- 8 testes Node: passaram.
- 5 testes XCTest: passaram (fontes/marca, handshake, helper ausente, seleção preservando conteúdo, símbolos).
- 1 teste XCUITest: passou (lançamento real, altura da janela, controles e navegação Projeto ↔ Endpoints).
- Captura da janela real revisada: docs/development/images/workspace.png.
- Assinatura do bundle e helper: codesign --verify --deep --strict passou.
- Recursos e handshake do bundle Release com env -i: passaram.

A primeira captura via cacheDisplay foi incompleta e não foi usada como evidência visual. XCUITest substituiu esse teste. NavigationSplitView apresentou layout incorreto na janela AppKit; HSplitView resolveu o problema, confirmado por teste de tamanho/cliques e captura (ADR 0002).

## Limites reais

Ainda não há analisador, endpoints, grafo funcional, persistência SQLite, histórico ou exportação de documentação. As seções correspondentes informam isso explicitamente. Não foram verificados VoiceOver completo, macOS 14 real, Apple Silicon, App Sandbox, Hardened Runtime ou notarização. O DMG inicial não tem a apresentação customizada do Finder. A fonte do título da janela e controles do sistema seguem o macOS.

## Próximo passo

Fase 2: sessão persistente Swift/Node com mensagens validadas, progresso, cancelamento e limites; depois Fase 3: primeiro adaptador Express com AST e fixtures reais.
