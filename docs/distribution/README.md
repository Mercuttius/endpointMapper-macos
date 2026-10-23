# Distribuição planejada

Artefato final: `EndpointMapper.dmg`, contendo `Endpoint Mapper.app` e link para `/Applications`. A prova da Fase 0 tem outro nome para não se confundir com o produto.

Bundle final: Contents/MacOS/EndpointMapper, Contents/Helpers/node, Contents/Resources/engine (JS compilado e parsers), fontes, licenças, assets e Info.plist. Resolver recursos via Bundle e nunca usar caminhos absolutos do desenvolvedor. Runtime obtido de release oficial fixada com checksum e avisos de licença; validar arquitetura com file/lipo e bibliotecas com otool. Não usar o Node global em runtime.

Pipeline: typecheck/test/build engine → compilar Xcode target → incorporar runtime/recursos/licenças → validar fontes e arquitetura → assinar auxiliares e bundle → smoke test relocável com ambiente limpo → montar staging com link Applications → hdiutil create → hdiutil verify → montar somente leitura → validar/copy/test → desmontar. Não apagar artefatos anteriores até novo build passar. Executar testes em destinos temporários, sem sobrescrever app instalado.

DMG: fundo escuro e logo sem modificações, organização Finder com app à esquerda e Applications à direita. Customização Finder não comprova instalação. Produzir builds experimentais cedo, mas nunca rotular probe sem interface como produto pronto.

Uso local: assinatura ad hoc quando necessária, sem conta paga. Distribuição pública: Developer ID, Hardened Runtime, avaliação dos entitlements do Node/JIT, assinatura de dentro para fora, notarização e stapling. Não desativar Gatekeeper. Custos/requisitos de conta devem ser confirmados na preparação da release.

Atualização Fase 1: scripts build-app.sh/build-dmg.sh/verify-bundle.sh implementados, com runtime e licenças incorporados. A personalização visual do Finder/DMG e análise real permanecem pendentes; nenhum probe atual é destinado a distribuição pública; sem validação de sandbox, Hardened Runtime, notarização ou Apple Silicon.

Atualização Fase 2: o bundle incorpora JavaScript compilado, ignore 7.0.5 e sua licença. A sessão persistente executa inventário real de metadados e exclusões, ainda sem analisar endpoints. Build de desenvolvimento 0.2.0 para Intel; assinatura ad hoc. O produto completo e a distribuição pública continuam sujeitos aos gates do roadmap.
