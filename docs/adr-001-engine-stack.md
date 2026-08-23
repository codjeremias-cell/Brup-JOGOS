# ADR-001 — Engine e stack do projeto

**Data:** 2026-08-22 · **Status:** Aceito (ratifica decisão provisória da F0/F1) · **Alcance:** Na Trilha da Herdeira v1.0

## Contexto

Dev solo (background Java), 8 h/semana, jogo 2D orientado a UI/texto, offline-first, Android primeiro, alvo < 150 MB. Decisão já viésada desde a Fase 1 (contradição C6 resolvida): este ADR registra a fundamentação, não reabre o debate.

## Alternativas avaliadas

| Critério (peso) | Godot 4.x + GDScript | Flutter + Flame |
|---|---|---|
| Ferramentas de jogo (editor, cenas, animação, áudio) (×3) | 5 | 2 |
| Iteração rápida de UI de jogo (Control nodes, temas) (×2) | 4 | 4 |
| Familiaridade de sintaxe p/ dev Java (×1) | 3 (estilo Python) | 5 (Dart ~ Java) |
| Testes unitários do núcleo (×2) | 4 (gdUnit4 headless) | 5 (test nativo) |
| Export Android/iOS e tamanho base (×2) | 4 (APK ~35 MB vazio) | 4 (~20 MB vazio) |
| Comunidade jogos indie pt-BR (×1) | 5 | 3 |

**Total ponderado: Godot 47 × Flutter 42.**

## Decisão

**Godot 4.x + GDScript.** O jogo é 90% interface de texto/carta/painel + fluxo de estados — o editor de cenas e o sistema de temas do Godot entregam isso com menos código que Flame (que exige montar à mão o que o Godot dá pronto). A vantagem de familiaridade do Dart não compensa a falta de ferramentas de jogo. O ponto fraco do Godot (testes) é neutralizado pela arquitetura: núcleo puro testável headless via gdUnit4.

## Consequências

- Núcleo de regras em GDScript puro (`RefCounted`, sem nós de cena) — ver ADR-002 (arquitetura).
- Pipeline de conteúdo permanece independente de engine (JSON → SQLite).
- Estimativa de build final: ~35 MB base + ~25 MB arte (postais WebP) + ~35 MB áudio (OGG) ≈ **95–110 MB < 150 MB** ✅
