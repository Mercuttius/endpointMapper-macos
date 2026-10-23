# Roadmap e matriz de suporte

## Capacidades atuais

Fases 0–2 implementadas. O inventário conta linguagens por extensão; isso não constitui reconhecimento de frameworks nem análise semântica.

| Ecossistema | Reconhecido | Parser | Framework detectado | Rotas | Dependências | Testes de adaptador |
|---|---|---|---|---|---|---|
| JS/TS Express, Fastify, NestJS | Não | Planejado: TS API | Não | Não | Não | Não |
| Python FastAPI, Flask, Django | Não | Planejado: Tree-sitter | Não | Não | Não | Não |
| Java Spring/JAX-RS, C# ASP.NET, PHP Laravel/Symfony | Não | Planejado | Não | Não | Não | Não |
| Go Gin/Echo/Fiber/Chi; Ruby Rails/Sinatra | Não | Planejado | Não | Não | Não | Não |
| Rust Actix/Axum/Rocket; Kotlin Ktor/Spring; Swift Vapor/Hummingbird | Não | Planejado | Não | Não | Não | Não |

## Etapas e gates

0. Arquitetura e viabilidade: contratos, identidade e probe Swift/Node incorporado. Gate: execução sem PATH de desenvolvimento, erros de protocolo testados. Distribuição e arquiteturas ainda precisam de validações adicionais.
1. Depende de 0: projeto Xcode, design system, fontes licenciadas, assets, splash, navegação, Settings/About e estados de erro. Gate: build + testes de recursos/bootstrap + inspeção visual/acessibilidade.
2. Depende de 0/1: actor de comunicação assíncrono, worker, progresso, cancelamento, limites e falhas. Gate: testes Swift/Node com processo encerrado, timeout, mensagens partidas e cancelamento.
3. Depende de 2: Express via AST, imports, routers, prefixos e middleware. Gate: fixtures positivas/negativas, router aninhado/importado, rota dinâmica, código inválido, isolamento e nenhuma alteração de arquivos.
4. Depende de 3: busca/filtros, inspector, código e grafo nativo. Gate: selecionar endpoint real → evidência → código; zoom/pan e navegação por teclado.
5. Depende de 3/4: Fastify e NestJS, cada qual com fixtures e capacidades explícitas. Sem anunciar suporte integral com apenas decorators reconhecidos.
6. Depende de 3/5: resolução de símbolos, chamadas e grafos arquiteturais. Gate: cada aresta possui evidência; desconhecidos permanecem explícitos.
7. Depende de 4/6: JSON/Markdown/CSV/HTML/OpenAPI 3.1 e exportação visual. Gate: validação de formatos, escape de conteúdo, schemas não inventados.
8. Depende de núcleo estabilizado: Python → Java/C#/PHP → demais linguagens. Gate independente por adaptador/versão.
9. Depende de 6: cache SQLite, invalidadores, monitoramento com debounce, snapshots/diff e busca global. Gate: equivalência análise incremental/completa e migrações testadas.
10. Transversal desde 0, consolidada após 4/7: app autocontido, DMG, fontes, licenças, assinatura local e testes de cópia/relocação. Gate: máquina sem ferramentas de desenvolvimento, sem rede, análise real.
11. Depende das capacidades selecionadas para release: segurança, benchmarks, regressão, VoiceOver, Intel/ARM e distribuição. Gate: evidências registradas, sem pendências mascaradas.

## MVP funcional

Escopo inicial: Express nas construções comprovadas. Abrir pasta, analisar sem executar/escrever no alvo, acompanhar/cancelar, listar e filtrar endpoints, consultar evidências/middlewares/handlers, abrir código, explorar grafo e exportar JSON/Markdown. Interface com identidade final, recentes persistidos em SQLite, splash real e fontes incorporadas. App e DMG relocáveis com Node interno. Nenhum framework adicional prometido.

Aceitação: análise da fixture e de projeto independente; hash dos arquivos antes/depois inalterado; erros legíveis; nenhum acesso de rede; execução sem Node global; testes de protocolo, adaptadores, persistência e UI; DMG montável com app e Applications; teste em cada arquitetura anunciada. Fases posteriores não são pré-condição para chamar essa versão de MVP, mas permanecem necessárias ao produto completo.
