# Endpoint Mapper

Aplicativo macOS nativo planejado para exploração estática de endpoints, totalmente local, com SwiftUI/AppKit e motor Node.js/TypeScript incorporado.

**Estado: Fase 2 — integração persistente e inventário local. Ainda não analisa endpoints.** Aplicativo SwiftUI/AppKit com splash, identidade incorporada e motor Node interno. Permite selecionar uma pasta, inventariar arquivos respeitando exclusões, acompanhar progresso, cancelar e reconectar após falhas. Nenhum framework é declarado suportado.

- [Resultados e limites da versão 0.2.0](docs/development/phase-2-results.md)
- [Sessão persistente e inventário](docs/development/phase-2.md)
- [Fundação nativa e build do aplicativo](docs/development/phase-1.md)
- [Arquitetura e modelo de dados](docs/architecture/README.md)
- [Identidade visual](docs/architecture/design-system.md)
- [Roadmap, matriz de suporte e aceitação](docs/architecture/roadmap.md)
- [Protocolo](shared/protocol/README.md)
- [Desenvolvimento e testes](docs/development/README.md)
- [Empacotamento e distribuição](docs/distribution/README.md)
- [Decisão arquitetural](docs/decisions/0001-native-helper.md)

```sh
npm ci --prefix engine --ignore-scripts
npm test --prefix engine
bash packaging/scripts/build-app.sh
bash packaging/scripts/build-dmg.sh
```

O logotipo fornecido permanece intacto em branding/original-logo. JetBrains Mono 2.304 e sua licença OFL estão incorporadas. Os arquivos do projeto não receberam uma licença de redistribuição escolhida unilateralmente; direitos do código e marca permanecem a definir pelo proprietário. Dependências terão avisos separados.
