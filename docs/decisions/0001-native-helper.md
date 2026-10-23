# ADR 0001 — UI nativa e motor incorporado

Status: aceito como baseline; 2026-10-19.

Decisão: SwiftUI/AppKit, macOS 14+, Node 24 incorporado e JSON-RPC por pipes. Motor separado do estado de UI; parsers não executam projetos. SQLite do sistema. Builds específicos por arquitetura primeiro. Sem Electron, WebView principal ou portas locais.

Consequências: assinatura e runtime precisam de pipeline próprio; acesso lógico não fornece App Sandbox. Universal Binary somente após testes de ambos os runtimes. Node nativo remove tipos no probe; produção compilará TypeScript estrito para JS com dependências fixadas. O probe não substitui typecheck, engine de análise ou testes de interface.

Revisitar: App Sandbox após spike de acesso entre processos; alternativas de parser por linguagem; benchmark antes de paralelismo extensivo.
