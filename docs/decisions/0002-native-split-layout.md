# ADR 0002 — Divisão de painéis na janela AppKit

Status: implementação da Fase 1.

A integração inicial de NavigationSplitView em uma janela controlada por AppKit apresentou dimensionamento incorreto: o tamanho mínimo do conteúdo expandia a janela, e restringi-la deixava botões fora da área clicável. O teste de interface detectou o problema.

Decisão: usar HSplitView, componente nativo SwiftUI baseado em divisão redimensionável, hospedado por NSHostingController. Manter estado de navegação no ViewModel e três regiões com limites de largura. AppKit continua controlando a ordem splash → janela principal. Não há interface web nem dependência externa.

NavigationSplitView poderá ser reavaliado se oferecer vantagem concreta para a navegação hierárquica futura. Não adicionar uma camada de navegação apenas para aparência.
