-- ============================================
-- 003_scenarios.sql
-- Escenarios versionados sobre una red base
-- ============================================

CREATE SCHEMA IF NOT EXISTS scenario;

-- Un escenario es una "variante" de la red base
CREATE TABLE scenario.scenario (
    id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        text NOT NULL UNIQUE,
    name        text NOT NULL,
    description text,
    base_net    text NOT NULL DEFAULT 'ieee14',
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Modificación declarativa sobre la red base
-- op: tipo de cambio. payload: parámetros en jsonb
CREATE TABLE scenario.modification (
    id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scenario_id int NOT NULL
                REFERENCES scenario.scenario(id) ON DELETE CASCADE,
    op          text NOT NULL
                CHECK (op IN ('line_out','gen_out','gen_add','load_scale')),
    target_id   int,
    payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
    note        text
);

CREATE INDEX idx_modification_scenario
    ON scenario.modification (scenario_id);