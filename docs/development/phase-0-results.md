# Resultados verificáveis — Fase 0

Data: 19/10/2026. Host Intel x86_64; Xcode 26.2; Swift 6.2.3; Node 24.19.0.

- Build Swift com deployment target macOS 14: passou.
- Handshake real com Node incorporado em Contents/Helpers: passou.
- Execução com env -i e PATH=/usr/bin:/bin: passou.
- Cópia do bundle para .build/relocation e novo handshake: passou; executable retornado aponta para a cópia.
- Oito testes de protocolo: 8 passaram, 0 falharam. Handshake, múltiplos frames, JSON inválido, envelope inválido, método desconhecido, versão incompatível, excesso de tamanho e frame truncado.
- Info.plist: plutil -lint passou.
- file: probe e Node são Mach-O x86_64.
- otool: Node local depende somente de frameworks/bibliotecas do sistema neste ambiente.
- SHA-256 do logo copiado e do original iguais: f2abeea688f33961f8cfda1f81d1f06a575f50d27c0256060a38ec1e9c5b0a2a.
- Extração de pixels sRGB: batRed #F73346, arrowYellow #FDDF33.

Não executados/entregues: typecheck TypeScript, projeto Xcode de UI, fontes, splash, SQLite, adaptadores, cancelamento de análise, testes de UI, DMG, assinatura de distribuição, App Sandbox, macOS 14 real e Apple Silicon. O probe valida somente viabilidade de lançamento/handshake; não é ponte assíncrona de produção nem aplicação gráfica pronta.

Próxima etapa: Fase 1, seguida do transporte assíncrono da Fase 2. Não iniciar vários adaptadores antes de estabilizar a integração.
