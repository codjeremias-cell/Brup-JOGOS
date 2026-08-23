# BACKLOG — Na Trilha da Herdeira (v1.0, pronto para importar)

Formato por épico; cada item é uma história com critério de aceite. Mapeado às fases do Plano de Construção.

## E1 — Motor de regras (`/core`) · P0 · F1
- [ ] E1.1 Projeto Godot 4.x + gdUnit4 rodando headless no GitHub Actions — CI verde no push
- [ ] E1.2 `scoring.gd`: bases 40/60/90/130/180; mult linear; r10=3,0 substitui; streak cap 5 — testes verdes
- [ ] E1.3 `turn_engine.gd`: PA/Verba/rank gates como erros-valor; imutabilidade de estado — testes
- [ ] E1.4 `clue_eligibility.gd`: estágio→low/mid/high; janelas por rank — testes
- [ ] E1.5 `candidate_panel.gd`: 8/12 candidatas, correta sempre, seed determinística, curados prioritários — testes
- [ ] E1.6 `discard_report.gd`: só atributos divergentes; elimina ≥2 quando possível; nunca a correta — testes
- [ ] E1.7 `progression.gd`: limiares XP exatos (500…56.400); respec=2 Maestria; ofertas=3 não possuídas — testes
- [ ] E1.8 Simulação sintética: 10k etapas × perfis cauteloso/equilibrado/apostador dentro da banda 55–70%

## E2 — Dados & pipeline (`/data`, `/tools`) · P0 · F0–F3
- [ ] E2.1 Ingestor JSON→SQLite executando `data/schema.sql` e carregando as 10 pilotos
- [ ] E2.2 Planilha mestra das 500 cidades (CSV versionado) com tier/status/responsável/data
- [ ] E2.3 Template de prompt para lotes assistidos de 25–30 cidades (few-shot = pilotos)
- [ ] E2.4 Expansão do pool de distratores até cobrir MVP completo
- [ ] E2.5 Lotes MVP: 60 cidades-em-caso + 40 apoio, todas validadas nas 7 regras

## E3 — UI/UX & arte · P0 · F2
- [ ] E3.1 Tema por tokens (paleta B + detalhes C em cartas/selos)
- [ ] E3.2 Tela Título + Hub/Escritório v1 (mapa com alfinetes reais das cidades acertadas)
- [ ] E3.3 Seleção de Caso + Investigação (carta, ações, painel, overlay Resolução)
- [ ] E3.4 Encontro/Grande Encontro (cenas curtas) + Álbum + Perfil + Configurações
- [ ] E3.5 Animações: envelope, selo de cera, carimbo, viagem
- [ ] E3.6 Acessibilidade: escala de fonte, AA, ≥48dp, TTS

## E4 — Persistência · P0 · F1
- [ ] E4.1 SaveRepository: blob JSON versionado em SQLite, autosave por etapa
- [ ] E4.2 Export/import manual de backup (compartilhar arquivo)

## E5 — Progressão & especializações · P1 · F3
- [ ] E5.1 Ranks 1–5 com desbloqueios funcionais completos
- [ ] E5.2 Escolha de especialização (UI + lógica) e respec por Maestria
- [ ] E5.3 Escritório cosmético v1 + álbum de postais com fatos reais
- [ ] E5.4 Recompensa da Carta: bounties por tier + cláusulas-bônus + Moral/carimbos

## E6 — Telemetria · P1 · F4
- [ ] E6.1 Eventos mínimos gravando na fila local (opt-in nas Configurações)
- [ ] E6.2 Envio em lote quando online + limpeza pós-envio
- [ ] E6.3 Painel simples de análise (planilha gerada dos eventos brutos)

## E7 — Áudio · P2 · F2
- [ ] E7.1 Trilhas regionais MVP (Brasil, México/C.América, menu, Encontro)
- [ ] E7.2 SFX essenciais (envelope, selo, carimbo acerto/falha neutra, postal, moeda)

## E8 — Loja & legal · P1 · F5
- [ ] E8.1 Ficha Google Play BR + ASO (ícone, screenshots, descrição)
- [ ] E8.2 Política de privacidade/LGPD (telemetria opt-in documentada)
- [ ] E8.3 Classificação IARC + checagem formal de marca ("Xenia Alvarenga" e título)

## E9 — Live-ops · P2 · F6
- [ ] E9.1 Rastro Diário (3 cidades, +20 Verba cada, sem punição)
- [ ] E9.2 Cadência mensal: 1 lote de cidades OU 1 evento — nunca os dois

---
**Marcos:** F1 = E1.1–E1.7 + E4 + playtest gate de diversão · F2 = E3+E7 · F3 = E2.5+E5+simulação verde · F4 = E6 · F5 = E8.
