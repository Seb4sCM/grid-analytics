-- ============================================
-- 004_sim.sql
-- Resultados de simulación (DC-PF / DC-OPF)
-- ============================================

CREATE SCHEMA IF NOT EXISTS sim;

-- Una corrida de simulación
CREATE TABLE sim.run (
    id           int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scenario_id  int NOT NULL REFERENCES scenario.scenario(id),
    model        text NOT NULL DEFAULT 'dc_opf'
                 CHECK (model IN ('dc_pf','dc_opf')),
    t_start      timestamptz NOT NULL,
    t_end        timestamptz NOT NULL,
    config       jsonb NOT NULL DEFAULT '{}'::jsonb,
    git_sha      text,
    started_at   timestamptz NOT NULL DEFAULT now(),
    finished_at  timestamptz,
    status       text NOT NULL DEFAULT 'running'
                 CHECK (status IN ('running','ok','failed')),
    error        text,
    CHECK (t_start < t_end)
);

-- Resultados por nodo y hora
CREATE TABLE sim.bus_result (
    run_id       int NOT NULL REFERENCES sim.run(id) ON DELETE CASCADE,
    ts_utc       timestamptz NOT NULL,
    bus_id       int NOT NULL REFERENCES network.bus(id),
    angle_rad    numeric(12,8),
    lmp_usd_mwh  numeric(12,4),
    PRIMARY KEY (run_id, ts_utc, bus_id)
);

CREATE INDEX idx_bus_result_bus
    ON sim.bus_result (bus_id, ts_utc);

-- Resultados por generador y hora
CREATE TABLE sim.gen_result (
    run_id       int NOT NULL REFERENCES sim.run(id) ON DELETE CASCADE,
    ts_utc       timestamptz NOT NULL,
    gen_id       int NOT NULL REFERENCES network.generator(id),
    p_mw         numeric(12,4) NOT NULL,
    PRIMARY KEY (run_id, ts_utc, gen_id)
);

-- Resultados por línea y hora
CREATE TABLE sim.line_result (
    run_id       int NOT NULL REFERENCES sim.run(id) ON DELETE CASCADE,
    ts_utc       timestamptz NOT NULL,
    line_id      int NOT NULL REFERENCES network.line(id),
    flow_mw      numeric(12,4) NOT NULL,
    loading_pct  numeric(8,4) NOT NULL,
    PRIMARY KEY (run_id, ts_utc, line_id)
);

-- KPIs agregados por hora
CREATE TABLE sim.kpi (
    run_id       int NOT NULL REFERENCES sim.run(id) ON DELETE CASCADE,
    ts_utc       timestamptz NOT NULL,
    total_cost   numeric(14,2),
    max_lmp      numeric(12,4),
    min_lmp      numeric(12,4),
    congested    int,
    renew_share  numeric(6,4),
    PRIMARY KEY (run_id, ts_utc)
);