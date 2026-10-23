# Fase 2 — Sessão persistente e inventário

A aplicação mantém um processo Node incorporado durante a sessão. AnalysisSession é um actor: correlaciona requisições, valida envelopes e progresso, impõe prazos e rejeita pendências quando o auxiliar falha. Filas privadas de leitura/escrita evitam bloquear MainActor e mantêm os frames em ordem. Cada sessão tem uma geração para descartar callbacks de processos antigos.

A UI oferece inventário, cancelamento, indicação de conexão, reconexão explícita e prazo configurável. Não há repetição automática de operações após falha. Trocar/fechar projeto cancela o trabalho e descarta dados parciais. Progresso e amostra de caminhos são transitórios; somente a resposta terminal é considerada inventário concluído.

## Operação real

project.scan percorre a pasta escolhida, informa contagens de arquivos/pastas, linguagens por extensão, exclusões, symlinks e avisos. Não faz parsing de código nem descobre endpoints. Nenhum framework é anunciado como suportado.

O motor lê somente metadados, diretórios e arquivos .gitignore regulares limitados a 64 KiB. Não segue symlinks encontrados, não executa scripts, não importa configurações e não instala dependências do projeto. Diretórios de dependências/builds são omitidos; regras .gitignore locais e aninhadas são interpretadas pela biblioteca ignore 7.0.5. Configurações globais do Git e .git/info/exclude não são lidas.

Limites: 50.000 entradas, profundidade 64, caminhos UTF-8 de até 2.048 bytes, até 100 avisos; resultados limitados são identificados como parciais. Erros em entradas individuais são avisos; raiz inválida é erro. A seleção de uma pasta não inicia inventário automaticamente.

Segurança é lógica, não App Sandbox. realpath/contenção, lstat e O_NOFOLLOW/O_NONBLOCK evitam seguir symlinks ou bloquear em arquivos .gitignore especiais. Não se promete isolamento de alterações hostis concorrentes nos diretórios; isolamento imposto pelo sistema permanece um trabalho separado.

## Desenvolvimento

```sh
npm ci --prefix engine --ignore-scripts
npm test --prefix engine
xcodebuild -project macos/EndpointMapper.xcodeproj -scheme EndpointMapper -destination 'platform=macOS,arch=x86_64' -derivedDataPath .build/xcode test
bash packaging/scripts/build-app.sh
bash packaging/scripts/build-dmg.sh
```

Dependências com versões fixas e package-lock.json. TypeScript 5.9.3, strict e noUncheckedIndexedAccess; o bundle contém JS compilado, o pequeno módulo ignore com licença e Node. O compilador e @types/node são dependências de desenvolvimento, não distribuídas no app. Após mudar o motor, executar npm run build --prefix engine antes de compilar diretamente no Xcode.

Falhas de protocolo são registradas no log nativo por categoria AnalysisSession; stderr do auxiliar é separado de stdout. Não registrar código-fonte ou caminhos do projeto nos logs técnicos.

## Testes relevantes

Node: framing, UTF-8, limites, handshake, parâmetros, sessão persistente, lotes ordenados, cancelamento, regras ignore, symlinks e preservação de arquivos.

Swift: requisições simultâneas, inventário real, timeout, reinício, processo encerrado, JSON inválido, tamanho excessivo, respostas fragmentadas e cancelamento que chega ao auxiliar. Peers com falhas são gerados exclusivamente pelos testes em diretórios temporários; nunca são incorporados ao aplicativo.

Interface: lançamento/navegação e seleção de pasta pelo diálogo nativo até inventário concluído, com conteúdo de arquivo verificado antes/depois.

## Próximo passo

Adaptador Express com TypeScript Compiler API: extração semântica de rotas, prefixos e routers; modelo universal de endpoint; fixtures positivas/negativas; visualização dos primeiros endpoints reais. Inventário não substitui esse analisador.
