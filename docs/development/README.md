# Desenvolvimento e testes

Requisitos de desenvolvimento: macOS 14+, Xcode e Node 24.19.x da arquitetura do host. O usuário do aplicativo empacotado não precisa instalar Node nem fontes.

```sh
npm ci --prefix engine --ignore-scripts
npm test --prefix engine
bash packaging/scripts/build-app.sh
xcodebuild -project macos/EndpointMapper.xcodeproj -scheme EndpointMapper -destination 'platform=macOS,arch=x86_64' -derivedDataPath .build/xcode test
bash packaging/scripts/build-dmg.sh
bash packaging/scripts/verify-bundle.sh '.build/xcode/Build/Products/Release/Endpoint Mapper.app'
```

O destino acima corresponde ao Mac Intel usado na validação; não comprova compatibilidade Apple Silicon. NODE_BINARY e NODE_LICENSE_FILE permitem informar o runtime e sua licença ao build. O projeto Xcode é gerado por packaging/scripts/generate-project.py. Após mudar arquivos TypeScript, compilar o motor antes de executar testes diretamente no Xcode. Não há instalação de dependências dos projetos analisados.

- [Fase 0: viabilidade](phase-0-results.md)
- [Fase 1: fundação nativa](phase-1.md)
- [Fase 2: sessão e inventário](phase-2.md)

TypeScript usa strict/noUncheckedIndexedAccess e lockfile. Testes Node cobrem protocolo e descoberta. XCTest cobre o transporte Swift/Node e recursos incorporados. XCUITest opera a seleção nativa e o inventário em uma pasta temporária, validando a preservação de seu conteúdo.

Adaptadores futuros expõem metadata/capabilities e analyze(context). Context fornece ASTs, resolvedor seguro, cancelamento e coletor de diagnósticos, sem executar o projeto. Cada adaptador entrega modelo universal e evidências. Fixtures devem cobrir acertos, falsos positivos, imports, caminhos dinâmicos e código inválido; a matriz de suporte somente muda após execução desses testes.
