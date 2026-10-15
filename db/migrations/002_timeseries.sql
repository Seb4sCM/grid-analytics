-- ============================================
-- 002_timeseries.sql
-- Series temporales de demanda y generación
-- ============================================

CREATE SCHEMA IF NOT EXISTS ts;

-- Catálogo de perfiles (una serie reutilizable)
CREATE TABLE ts.profile (
    id          int PRIMARY KEY,
    code        text NOT NULL UNIQUE,
    kind        text NOT NULL
                CHECK (kind IN ('demand','solar','wind','hydro')),
    description text,
    tz          text NOT NULL DEFAULT 'UTC',
    source      text NOT NULL
);

-- Valores de cada perfil, en el tiempo
CREATE TABLE ts.profile_value (
    profile_id  int NOT NULL REFERENCES ts.profile(id),
    ts_utc      timestamptz NOT NULL,
    value       numeric(12,6) NOT NULL,
    PRIMARY KEY (profile_id, ts_utc)
);

-- Índice para consultas por rango de tiempo
CREATE INDEX idx_profile_value_ts ON ts.profile_value (ts_utc);

-- Mapeo: qué perfil aplica a qué carga, con factor de escala
CREATE TABLE ts.load_profile_map (
    load_id     int NOT NULL REFERENCES network.load(id),
    profile_id  int NOT NULL REFERENCES ts.profile(id),
    scale       numeric(10,4) NOT NULL DEFAULT 1.0,
    PRIMARY KEY (load_id, profile_id)
);