# ADR 0003 — Sessão persistente com transporte limitado

Status: implementado na Fase 2.

Um processo Node permanece ativo por sessão da aplicação. O actor AnalysisSession correlaciona IDs, controla prazos e cancela requisições. Após falha, pendências são rejeitadas e a reconexão é explícita. Gerações impedem que callbacks de um processo anterior afetem a nova sessão.

Frames JSON delimitados por newline têm limite de 64 KiB. Uma fila serial escreve; uma fila dedicada lê com Darwin.read e aguarda entrega ao actor antes de continuar. A leitura retorna os bytes disponíveis sem esperar preencher um bloco ou receber EOF, necessário para requisições/respostas em um processo persistente. O protocolo valida sequência e requestId dos eventos.

O inventário usa iteração assíncrona limitada e cede execução entre entradas, permitindo progresso e cancelamento no mesmo processo. Não há parsing pesado nesta fase; futuros adaptadores devem avaliar workers isolados para não bloquear cancelamento.

A UI retém apenas uma amostra de 100 caminhos e publica resultado final após resposta terminal. Cancelamento descarta parciais. Testes cobrem múltiplas requisições, mensagens fragmentadas, encerramento, timeout, reinício e cancelamento confirmado pelo auxiliar.
