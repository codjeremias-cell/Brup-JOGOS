# NA TRILHA DA HERDEIRA (The Heiress Trail)
## Game Design Document — v1.0 consolidada

| Campo | Valor |
|---|---|
| Versão | 1.0 |
| Data | 2026-08-22 |
| Autor | Jeremias Cardoso |
| Status | Congelada para produção (F0 do Plano de Construção) |
| Fontes | Prompt Mestre v2.0 + Plano de Construção v1.0 + decisões das Fases 1–6 |

---

## 1. VISÃO

Jogo mobile de **investigação tática em turnos** com progressão RPG, offline-first, Android primeiro. O detetive segue um jogo consentido de gato e rato contra **Xenia Alvarenga**, herdeira bilionária que publica enigmas de propósito e financia quem a alcançar. Termo canônico do gênero: *investigação tática em turnos* (nunca "combate").

**Pilares (toda decisão se subordina a eles):**
- **P1 Dedução genuína** — dicas resolvíveis por raciocínio; distratores curados; zero sorte como mecânica
- **P2 O mundo é a recompensa** — falha ensina geografia; postal traz fato real verificado
- **P3 Maestria visível** — ranks mudam o formato da dica e o painel; especializações criam builds
- **P4 Respeito ao tempo** — etapa 3–6 min; sem punição reversível por dinheiro; sem grind obrigatório

## 2. NARRATIVA

- **Xenia Alvarenga**: alta, morena, cabelos negros longos, espirituosa. Voz: ironia fina + amor genuíno pelos lugares. Assina com o inicial e um selo de cera com monograma. *(Nomes alternativos descartados: Ondina Vasconcelos, Aurélia Sampaio. Checagem formal de marcas antes da loja.)*
- **Arco em 3 atos:** teste de olhar → confidência (o avô cartógrafo) → diálogo entre iguais.
- **Informantes:** Dona Filomena (clima/relevo) · Sr. Aristides (selos/moedas/história) · Chef Kaya (gastronomia) · Professora Íris (línguas/topônimos).
- **Finais (escolha livre ao completar a campanha):** Sociedade (Academia de Rastros) · Sucessão (o detetive herda o selo) · Rota inversa (ela passa a seguir o detetive).
- Tom: pôster vintage de turismo, selos, carimbos. Sem violência.

## 3. CORE LOOP

### 3.1 Etapa (turno)
Carta anônima (nível low/mid/high conforme posição: etapas 1–2 low · 3–4 mid · 5 high) + painel de candidatas (**8** nos ranks 1–3 · **12** nos ranks 4–6 · busca livre com filtros nos ranks 7–10). **3 PA (4 a partir do rank 5)**.

| Ação | Custo | Efeito | Desbloqueio |
|---|---|---|---|
| Analisar Pista | 1 PA | Traduz trecho metafórico (campo `analysis`) | sempre |
| Consultar Informante | 1 PA + 15 Verba | Dica da categoria escolhida | sempre |
| Arquivo Secreto | 2 PA | Remove 2 candidatas erradas aleatórias | rank 6 (Historiador: 1 PA) |
| Radar de Fuso | 1 PA | Faixa de fuso + trava continente | rank 9 |
| Viajar | 0 PA | Resolve a etapa | sempre |

### 3.2 Resolução
`XP = round(Base(tier) × Mult(rank) × (1+0,15×PA livres) × (1+0,10×min(streak,5)) × (1+bônus_cláusula))`
- Base(tier): **40·60·90·130·180** · Mult(rank): `1+0,08(r−1)` até r9; **r10 substitui por ×3**
- Streak/carimbos de Moral: acertos seguidos na 1ª tentativa, máx. 5 (+50%); zera na falha

### 3.3 Recompensa da Carta (bounty)
Declarada no selo antes de jogar. Base por tier (1ª tentativa / 2ª = 50% / 3ª = 0):

| Tier | Verba | Reputação |
|---|---|---|
| 1 | 30 | +10 |
| 2 | 40 | +12 |
| 3 | 55 | +15 |
| 4 | 70 | +18 |
| 5 | 90 | +22 |

Cláusula-bônus opcional impressa na carta (máx. 1): acerto na 1ª (+50% XP) · ≤1 PA gasto (+10 Rep) · sem informantes (+15 Verba).

### 3.4 Falha
1. Falha = −15 Reputação, streak zera, chega o **Relatório de Descarte**: afirmação negativa verdadeira gerada por atributos divergentes (continente, hemisfério, família linguística, litoral, fuso); candidatas violadas são marcadas/eliminadas.
2. 3 falhas: etapa reinicia com outro conjunto de dicas do mesmo tier (anti-decoreba); o caso nunca volta ao zero; sem punição adicional.

## 4. PROGRESSÃO

| Rank | Título | XP acum. | Desbloqueio |
|---|---|---|---|
| 1 | Detetive Aprendiz | 0 | tutorial embutido no Caso 1 |
| 2 | Auxiliar de Campo | 500 | dicas de clima/relevo |
| 3 | Investigador Júnior | 1.300 | filtro por continente · **1ª especialização** |
| 4 | Detetive Urbano | 2.580 | 12 candidatas · dicas gastronômicas |
| 5 | Inspetor de Casos | 4.630 | 4 PA · **2ª especialização** |
| 6 | Perito Investigador | 7.910 | Arquivo Secreto |
| 7 | Detetive de Elite | 13.150 | busca livre · **3ª especialização** |
| 8 | Mestre da Lógica | 21.540 | 2 consultas informantes/dica |
| 9 | Grão-Investigador Internacional | 34.960 | Radar de Fuso · **4ª especialização** |
| 10 | Super Detetive Lendário | 56.400 | multiplicador ×3 |

Duração-alvo: rank 10 em **~26–29 h** ✅

**Especializações** (escolhe 1 entre 3 não possuídas, ranks 3/5/7/9):
Geógrafo (clima grátis +detalhe) · Gastrônoma (prato→região; consulta 10 Verba) · Historiador(a) (séculos nos marcos; Arquivo 1 PA) · Linguista (família linguística revelada; estrangeiras marcadas) · Cartógrafo(a) (elimina 1 candidata/etapa de graça) · Cosmopolita (+10% XP; duplicada→10 Verba).
**Respec:** 2 Pontos de Maestria · cosmético raro: 3–5 · título honorário: 10. Maestria vem de caso perfeito (+1) e Grande Encontro perfeito (+2).

## 5. ECONOMIA

- **Verba:** fontes = bounties + cláusulas + caso completo (+40) + Encontros (+75/+300) + Diário (+20/cidade). Drenos = informantes (15) + cosméticos do escritório (100–800). Saldo esperado: **+140 a +280 por caso** (escassez leve).
- **Reputação:** faixas 0/150/400/900/1500 → títulos e itens; nunca bloqueia progresso; piso 0.
- **Monetização (ratificada — Modelo B):** free + rewarded ads **opcionais** (1 consulta extra ou 1 candidata eliminada; teto 3/dia; **nunca após falha**) + compra única Apoiadora **R$ 19,90** (remove prompts + cosmético). Sem energia. Nenhuma venda de progressão.

## 6. CONTEÚDO

- **Schema JSON v2.1** (`data/schema.sql` para SQLite): i18n pt-BR/en-US/es obrigatório; `language_family` e `utc_offset` (v2.1); `clue_id` estável `{city_id}-{tier}-NN`.
- **7 regras de validação** automatizadas em `tools/validate_cities.ps1`: cobertura ≥9 dicas (≥3/tier, ≥4 categorias) · unicidade (identical/Jaccard>70% bloqueados em mid/high) · distratores 4–7 existentes · sensibilidade marcada · fonte por dica · i18n completo · rastreabilidade.
- **14 capítulos regionais → 94 casos → 470 cidades + 30 reserva:**

| Região | cidades→casos |
|---|---|
| Brasil | 30→6 |
| Andina/Cono Sur | 40→8 |
| México/Am. Central | 30→6 |
| EUA/Canadá | 50→10 |
| Europa Mediterrânea | 35→7 |
| Europa Ocidental | 40→8 |
| Europa Centro-Oriental | 35→7 |
| Norte da África | 25→5 |
| Oriente Médio | 25→5 |
| Sul da Ásia | 25→5 |
| Sudeste Asiático | 30→6 |
| Leste Asiático | 30→6 |
| África Subsaariana | 45→9 |
| Oceania | 30→6 |

- **MVP (soft launch):** Brasil + México/Am. Central = 12 casos (60 cidades-em-caso) + 40 de apoio = 100 cidades na base.
- Pipeline: planilha mestra → seed curado à mão → lotes assistidos de 25–30 → checklist humano de 8 itens → validador → ingestão versionada (`content_version` corrige conteúdo sem atualizar app).

## 7. UX/UI E ARTE

Wireflow: Título → Hub/Escritório → Seleção de Caso → **Investigação** ⇄ overlay Resolução → Encontro → Álbum · Perfil · Configurações. Estados vazio/carregando/erro em todas. Botões ≥48 dp, contraste AA, fonte escalável, TTS das cartas.

**Direção adotada (aprovada na Fase 4):** híbrido **B+C** — base "pôster turístico flat" (mostarda #E0A32E, verde #6F8F4F, azul #2E6E8E, off-white #FAF6EE; Jost caps) + detalhes "papel & colagem filatélica" apenas em cartas/selos (kraft #D8C49A, carimbo #B23A2E; Courier Prime/Caveat).

## 8. ÁUDIO

Trilhas regionais (12 famílias + menu + temas de Encontro) e 16 SFX listados na Fase 4; SFX de falha neutro-informativo (P4).

## 9. TÉCNICA

- **Stack:** Godot 4.x + GDScript (ADR-001, ponderação 47×42 vs Flutter+Flame). Build-alvo 95–110 MB < 150 MB.
- **Arquitetura:** `/core` funções puras (sem engine/arquivo; RNG semeado; saída só em chaves i18n) ← `/game` e `/data`; `/tools` para pipeline. Contratos-chave: `apply_action`, `resolve_travel`, `compute_xp`, `build_panel`, `build_discard`, `rank_for_xp` (ver Fase 5).
- **Dados:** SQLite embarcado gerado dos JSONs (~2,5 MB texto ×500 cidades); save local blob versionado + export manual; telemetria opt-in em fila local com envio em lote.
- **Testes:** gdUnit4 headless no GitHub Actions; suites scoring/engine/panel/discard/eligibility/progression/**simulation** (10k etapas sintéticas × 3 perfis dentro da banda 55–70%). Cobertura ≥80% no `/core`.

## 10. TELEMETRIA E QUALIDADE

Eventos: `etapa_iniciada`, `acao_usada(tipo,rank)`, `viagem(resultado,city_id,tentativa,clue_ids_vistos)`, `caso_concluido(tempo,falhas)`, `rank_up`, `sessao(duracao)`. Banda-alvo de acerto na 1ª tentativa: **55–70% por tier**; dica fora da banda entra em revisão via `content_version`.

Metas soft launch: D1 ≥35% · D7 ≥12% · sessão ≥12 min · crash-free ≥99% · rating ≥4,3.

## 11. ROADMAP

| Versão | Conteúdo | Sistemas |
|---|---|---|
| MVP | 100 cidades, Brasil+México/CA | ranks 1–5, 2 escolhas de spec, álbum, escritório v1 |
| v1.0 | 300 cidades, 8 capítulos | ranks 1–8, 6 specs completas |
| v1.5+ | 470+reserva | ranks 9–10, Rastro Diário, eventos sazonais |

Fases do Plano: F0 fundação ✓(esta GDD) → F1 protótipo (gate de diversão!) → F2 vertical slice → F3 conteúdo+sistemas → F4 alpha → F5 soft launch BR → F6 v1.0+iOS.

## 12. HISTÓRICO DE DECISÕES (contradições resolvidas)

C1 monetização provisória→ratificada Fase 3 · C2 capítulos regionais (14) · C3 painel completa por pool em runtime · C4 MVP 60+40 cidades · C5 falha reinicia etapa, nunca o caso · C6 ADR em vez de reabrir stack · C7 unificado XP único · C8 ×3 substitui mult no r10 · C9 piso de casos/capítulo = 5 · C10 distratores curados + complemento runtime · Ajuste F2: Recompensa da Carta (bounty + cláusulas + Moral) · Decisões operador: do zero, Modelo B, i18n trilíngue, Android 8+/2GB/720p, Gmail no git público.

*— fim —*
