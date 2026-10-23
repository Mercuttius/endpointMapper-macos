# Identidade visual

O original está em branding/original-logo/logo.png, copiado sem alterações. A imagem inteira, inclusive o fundo preto, será mantida. Gerar apenas escalas proporcionais para AppIcon e imagens; não recortar, remover fundo, redesenhar ou acrescentar elementos.

Cores oficiais: branding/colors.json, obtidas por packaging/scripts/extract-colors.swift. O algoritmo converte pixels para sRGB e escolhe o pixel mais frequente dentro de máscaras cromáticas vermelha e amarela, com desempate lexicográfico. Preserva o arquivo fonte. Como há variação na imagem, os tokens representam cores predominantes, não uma substituição das cores do logo.

Tokens neutros: background.primary #0D1117, secondary #161B22, tertiary #21262D, deep #010409; border #30363D; text.primary #E6EDF3, secondary #8B949E, muted #6E7681. Vermelho e amarelo como acentos, nunca únicos indicadores de estado. Contraste deverá ser medido por combinação, especialmente texto muted em painéis; não assumir acessibilidade somente pela paleta.

Tipografia: JetBrains Mono Regular/Medium/SemiBold/Bold incorporadas e registradas por CoreText antes de criar janelas. Sem instalação global. Licença SIL OFL 1.1 será distribuída junto aos arquivos oficiais. Falha de registro é erro verificável, não fallback silencioso. Arquivos oficiais 2.304 incorporados na Fase 1 em macos/Resources/Fonts. Tamanhos base: título 24, seção 16, corpo 13, metadados 11, código 12; escala configurável. Menus/controles estritamente gerenciados pelo macOS respeitam as fontes do sistema.

Espaçamento 4/8/12/16/24/32; raios 6/10; borda 1; ícones 14/16/20. Estados normal, hover, focus, selected, disabled, error são tokens compartilhados. Foco por teclado sempre visível. SF Symbols validados no macOS 14, usando Label nas ações e accessibilityLabel em botões sem texto. Preferir doc.on.doc para copiar, folder.badge.plus para abrir, stop.circle para cancelar, square.and.arrow.up para exportar.

Splash: NSWindow própria com NSHostingView, fundo preto e logo proporcional. AppKit impede a janela principal de aparecer antes do término do bootstrap. Inicializar fontes, persistência e handshake assíncrono. Sem atraso artificial; fade breve apenas quando movimento reduzido estiver desativado. Falha exibe recuperar/encerrar, sem sucesso fictício.

Janela principal: NavigationSplitView, sidebar de projetos/visões, conteúdo com lista/mapa/código, inspector de evidências. Nenhum endpoint fictício fora de previews/fixtures. Settings e About compartilham os tokens. Canvas para grafo; NSTextView somente leitura para código. Fase 1 implementa splash, navegação, inspector, Settings e About. Canvas e visualizador de código permanecem para a Fase 4.

## Identidade de suíte — 22/10/2026

A splash e o cabeçalho lateral seguem as referências fornecidas do Webhook Box. A splash usa janela de 1320 × 840 pontos, estimada a partir da captura Retina, limitada à área útil em telas menores. Logo original centralizado em área de 350 × 350 pontos; nome unido EndpointMapper, com Endpoint amarelo #FDDF33 e Mapper vermelho #F73346. Letreiro JetBrains Mono Bold compartilhado por BrandWordmark.

Fundo da splash e da lateral: vermelho quase preto #100609. Cabeçalho horizontal com imagem de 56 pontos e letreiro de 18 pontos; largura lateral mínima de 250 pontos para preservar a composição em uma linha. O arquivo original do símbolo permanece intacto. A splash continua vinculada à inicialização real do motor, sem espera artificial.
