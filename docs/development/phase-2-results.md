# Fase 2 — Resultados de validação

Data: 20/10/2026. Ambiente: Mac Intel x86_64, Xcode 26.2, Node 24.19.0. Versão 0.2.0 (build 2).

## Entregue

Sessão Swift/Node persistente, requisições correlacionadas, progresso limitado, cancelamento, prazos e reconexão explícita. Inventário de arquivos com regras .gitignore, exclusões, contagens por extensão e avisos de resultados parciais. Nenhum código do projeto é executado; endpoints ainda não são analisados.

Componentes principais: macos/Services/AnalysisSession.swift, RPCValue.swift, macos/ViewModels/WorkspaceModel.swift, macos/Features/WorkspaceView.swift; engine/src/protocol e engine/src/discovery. Scripts de empacotamento incorporam o motor compilado e a licença de ignore. Contrato em shared/protocol/README.md; decisão de transporte em docs/decisions/0003-persistent-session.md.

## Evidências executadas

- Motor: 19 testes aprovados, 0 falhas; .build/engine-tests.log.
- XCTest: 12 testes aprovados, 0 falhas; inclui recursos, seleção preservando arquivo, requisições simultâneas, inventário, cancelamento, timeout/reinício, processo encerrado, JSON inválido, frame excessivo e UTF-8 fragmentado. Registro: .build/phase2-tests.log.
- XCUITest: navegação aprovada na execução completa. O novo teste de inventário falhou inicialmente porque a digitação sintetizada perdeu caracteres e o prazo de consulta do seletor era curto. Corrigido com inserção integral do caminho, conferência do valor e espera pelo fechamento do campo de navegação. A execução direcionada final passou: .build/test-inventory.log, resultado Test-EndpointMapper-2026.10.20_19-37-42--0300.xcresult. Não se declara a execução completa anterior como aprovada; ambos os testes de interface têm execução aprovada individualmente.
- Captura do inventário inspecionada: images/inventory.png. Seleção nativa de pasta, 1 arquivo TypeScript, 1 exclusão de dependência, fonte intacta.
- Build Release aprovado: .build/phase2-release.log. Assinatura ad hoc e verificação deep/strict aprovadas.
- DMG criado e verificado por hdiutil; montagem somente leitura com app e link /Applications. Copiado para .build/install-check-phase2, verificado e desmontado.
- Motor da cópia extraída iniciado com ambiente PATH=/usr/bin:/bin: initialize retornou versão 0.2.0/runtime v24.19.0; project.scan retornou 1 arquivo, 1 exclusão, TypeScript: 1, nenhum aviso, truncated=false. Conteúdo de api.ts preservado. Shutdown concluído com código 0.

## Artefatos

- dist/Endpoint Mapper.app
- dist/EndpointMapper.dmg (~48 MiB)

Build local para Intel, sem notarização. Apple Silicon, personalização visual do Finder/DMG e validação em máquina sem ferramentas de desenvolvimento permanecem pendentes. O teste relocável valida o motor incorporado com ambiente limpo; não substitui essa validação em outra máquina.

## Próxima etapa

Fase 3: analisador Express por AST, com rotas, métodos, prefixos, routers, handlers, middlewares e evidências integradas à interface. Nenhum framework é declarado suportado nesta versão.
