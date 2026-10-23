# Ajuste de identidade — 22/10/2026

Splash ampliada conforme as proporções da captura do Webhook Box, logo centralizado e letreiro EndpointMapper unido em amarelo/vermelho. Fundo vermelho quase preto compartilhado com a lateral. Cabeçalho lateral horizontal com logo e mesmo letreiro. Símbolo original preservado byte a byte.

Arquivos: macos/DesignSystem/Theme.swift, macos/Features/StartupViews.swift, macos/Features/WorkspaceView.swift, macos/App/EndpointMapperApp.swift e docs/architecture/design-system.md.

Validação: build Release aprovado; teste existente testLaunchAndNavigation aprovado; renderização nativa de SplashView e captura real da janela principal inspecionadas. Assinatura e recursos do bundle verificados; handshake com motor incorporado aprovado; DMG recriado e checksum validado por hdiutil.

Evidências locais: .build/branding-release.log, .build/branding-ui.log, .build/branding-dmg.log. Imagens: images/splash-suite.png (renderização da view de produção), images/workspace-suite.png (captura do XCUITest).

Artefatos atualizados: dist/Endpoint Mapper.app e dist/EndpointMapper.dmg. Mantidas as condições do build local Intel 0.2.0, sem notarização. Não foi instalada uma cópia em /Applications.
