# Protocolo v1 — motor 0.2.0

JSON-RPC 2.0 por stdin/stdout, UTF-8, um frame por LF. Sem portas. stderr exclusivo de diagnóstico técnico. IDs strings de 1–128 caracteres; IDs ativos não podem ser reutilizados. Inicialização é obrigatória antes dos demais métodos. O app só fornece raízes selecionadas pelo usuário.

## Métodos implementados

| Método | Parâmetros | Resultado |
|---|---|---|
| initialize | protocolVersion: 1 | protocolVersion, engineVersion, capabilities, runtime, architecture, executable |
| ping | objeto vazio | alive: true |
| project.scan | root: caminho absoluto | files, directories, ignored, symlinks, languages, warnings, truncated |
| cancel | requestId: ID do inventário | cancelled: boolean |
| shutdown | objeto vazio | stopped: true; aborta operações e encerra leitura |

```json
{"jsonrpc":"2.0","id":"1","method":"initialize","params":{"protocolVersion":1}}
{"jsonrpc":"2.0","id":"2","method":"project.scan","params":{"root":"/pasta/escolhida"}}
```

Capabilities: ping, project.scan, cancel, shutdown. Nenhum recurso de descoberta de endpoints é declarado.

Notificações project/progress e project/batch incluem params.requestId, sequence (inicia em zero e cresce por operação), kind, files, directories e paths. Progresso traz paths vazio; lotes trazem no máximo 16 caminhos relativos. Os lotes são amostras transitórias na UI, não um snapshot persistido. A resposta final contém contagens autoritativas.

## Limites e ciclo de vida

Frames recebidos: máximo 64 KiB (sem LF). Saída do motor: fila de até 1 MiB, write callbacks e backpressure. Swift limita requisições a 8 KiB e 32 pendências. Leitura com buffers limitados, UTF-8/JSON inválido encerra a sessão. Apenas um inventário simultâneo. Mensagens recebidas são validadas, incluindo IDs, sequência e contagens.

Handshake: 5 s. Inventário: 120 s por padrão, configurável em Settings. Timeout encerra o helper e rejeita todas as pendências. Cancelamento da Task envia cancel, descarta resultados parciais e espera até 2 s pela resposta terminal original; se o motor não confirmar, a sessão é encerrada. Terminação forçada após 500 ms caso SIGTERM não seja atendido. EOF do cliente aborta inventários. Ao encerrar o app, o stdin é fechado e o helper terminado.

Reinício só por ação explícita. Cada processo tem geração própria; respostas atrasadas não podem contaminar nova sessão. IDs cancelados ficam em um conjunto limitado para tolerar respostas tardias. Falha de leitura, saída inesperada, mensagem inválida ou estouro de tamanho aparece como desconexão recuperável.

## Erros

- -32700: JSON/UTF-8/frame inválido (frame excessivo ou EOF parcial também encerra com exit 65).
- -32600: envelope ou ID ativo inválido.
- -32601: método não implementado.
- -32602: parâmetros/versão inválidos.
- -32002: initialize obrigatório.
- -32001: inventário já em andamento.
- -32010: raiz não pôde ser lida.
- -32800: operação cancelada (resposta ao ID original).

Progresso nunca implica conclusão. Dados omitidos por limites ou erros de leitura são identificados como parciais.
