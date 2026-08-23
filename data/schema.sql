-- ============================================================================
-- NA TRILHA DA HERDEIRA — Modelo de dados embarcado (SQLite 3)
-- schema_version 2.1 (v2.1 = +language_family, +utc_offset; ver ADR-002/F5)
-- Gerado a partir dos JSONs em /data/cities pelo pipeline /tools (F3).
-- ============================================================================

CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
  -- linhas esperadas: ('schema_version','2.1'), ('content_version','2026.08.001')
);

CREATE TABLE cities (
  city_id         TEXT PRIMARY KEY,
  name_pt         TEXT NOT NULL,
  name_en         TEXT NOT NULL,
  name_es         TEXT NOT NULL,
  country_pt      TEXT NOT NULL,
  country_en      TEXT NOT NULL,
  country_es      TEXT NOT NULL,
  iso2            TEXT NOT NULL,
  continent       TEXT NOT NULL CHECK (continent IN
                    ('south_america','north_america','europe','asia','africa','oceania')),
  difficulty_tier INTEGER NOT NULL CHECK (difficulty_tier BETWEEN 1 AND 5),
  lat             REAL NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lon             REAL NOT NULL CHECK (lon BETWEEN -180 AND 180),
  timezone        TEXT NOT NULL,           -- IANA, ex.: America/Sao_Paulo
  utc_offset      REAL NOT NULL,           -- horas, ex.: -3.0 (Radar de Fuso)
  language_family TEXT NOT NULL,           -- ex.: 'romance' (Linguista/Descarte)
  currency_iso    TEXT NOT NULL,
  languages       TEXT NOT NULL,           -- CSV, ex.: 'pt'
  climate_tag     TEXT NOT NULL,
  flag_iso        TEXT NOT NULL,
  art_ref         TEXT NOT NULL,
  fact_pt         TEXT NOT NULL,
  fact_en         TEXT NOT NULL,
  fact_es         TEXT NOT NULL,
  tags            TEXT NOT NULL            -- CSV, ex.: 'praias,musica'
);

CREATE TABLE clues (
  clue_id          TEXT PRIMARY KEY,       -- estável: '{city_id}-{tier}-NN'
  city_id          TEXT NOT NULL REFERENCES cities(city_id),
  tier             TEXT NOT NULL CHECK (tier IN ('low','mid','high')),
  category         TEXT NOT NULL,          -- geografia, gastronomia, marco, historia,
                                           -- natureza, idioma_cultura, economia...
  text_pt          TEXT NOT NULL,
  text_en          TEXT NOT NULL,
  text_es          TEXT NOT NULL,
  analysis_pt      TEXT,                   -- opcional (Analisar Pista)
  analysis_en      TEXT,
  analysis_es      TEXT,
  uniqueness_scope TEXT NOT NULL CHECK (uniqueness_scope IN
                     ('global','regional','continental')),
  spoiler_level    INTEGER NOT NULL CHECK (spoiler_level BETWEEN 1 AND 3),
  sensitivity_reviewed INTEGER NOT NULL CHECK (sensitivity_reviewed IN (0,1)),
  fact_source      TEXT NOT NULL
);

CREATE INDEX idx_clues_city     ON clues(city_id);
CREATE INDEX idx_clues_tier_cat ON clues(tier, category);

CREATE TABLE distractors (
  city_id      TEXT NOT NULL REFERENCES cities(city_id),
  position     INTEGER NOT NULL CHECK (position BETWEEN 1 AND 7),
  distractor_id TEXT NOT NULL REFERENCES cities(city_id),
  PRIMARY KEY (city_id, position)
);

-- Progresso do jogador: um único blob JSON comprimido (save local simples,
-- export/backup manual copia o blob). Estrutura versionada dentro do JSON.
CREATE TABLE save_state (
  slot       INTEGER PRIMARY KEY DEFAULT 1,
  payload    BLOB NOT NULL,
  updated_at INTEGER NOT NULL              -- unix epoch
);

-- Telemetria opt-in: fila local; envio em lote quando online; limpeza pós-envio.
CREATE TABLE telemetry_queue (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL,                -- etapa_iniciada, acao_usada, viagem...
  payload    TEXT NOT NULL,                -- JSON do evento
  created_at INTEGER NOT NULL,
  sent_at    INTEGER                       -- NULL = pendente
);

CREATE INDEX idx_telemetry_pending ON telemetry_queue(sent_at) WHERE sent_at IS NULL;

CREATE VIEW v_city_counts AS
  SELECT continent, COUNT(*) AS total FROM cities GROUP BY continent;
