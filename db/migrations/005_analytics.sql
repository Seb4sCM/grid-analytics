-- ============================================
-- 005_analytics.sql
-- Vistas analíticas para Power BI
-- ============================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================
-- 1. Mapa de nodos (para visual geográfico)
-- ============================================
CREATE VIEW analytics.v_map_bus AS
SELECT
    b.id        AS bus_id,
    b.name,
    b.kv,
    b.lat,
    b.lon,
    b.region,
    b.is_slack
FROM network.bus b;

-- ============================================
-- 2. Mapa de líneas (con coordenadas de extremos)
-- ============================================
CREATE VIEW analytics.v_map_line AS
SELECT
    l.id            AS line_id,
    l.from_bus,
    l.to_bus,
    bf.lat          AS from_lat,
    bf.lon          AS from_lon,
    bt.lat          AS to_lat,
    bt.lon          AS to_lon,
    l.s_max_mva
FROM network.line l
JOIN network.bus bf ON bf.id = l.from_bus
JOIN network.bus bt ON bt.id = l.to_bus;

-- ============================================
-- 3. Congestión por línea (sobre todos los runs)
-- ============================================
CREATE VIEW analytics.v_line_congestion AS
SELECT
    lr.run_id,
    lr.line_id,
    l.from_bus,
    l.to_bus,
    avg(lr.loading_pct)                              AS avg_loading,
    max(lr.loading_pct)                              AS max_loading,
    count(*) FILTER (WHERE lr.loading_pct > 90)      AS hours_over_90,
    count(*)                                         AS total_hours
FROM sim.line_result lr
JOIN network.line l ON l.id = lr.line_id
GROUP BY lr.run_id, lr.line_id, l.from_bus, l.to_bus;

-- ============================================
-- 4. LMP por nodo y hora
-- ============================================
CREATE VIEW analytics.v_lmp_by_bus_hour AS
SELECT
    br.run_id,
    br.ts_utc,
    br.bus_id,
    b.name       AS bus_name,
    b.region,
    br.lmp_usd_mwh
FROM sim.bus_result br
JOIN network.bus b ON b.id = br.bus_id;

-- ============================================
-- 5. Despacho por tecnología y hora
-- ============================================
CREATE VIEW analytics.v_dispatch_by_fuel AS
SELECT
    gr.run_id,
    gr.ts_utc,
    g.fuel,
    sum(gr.p_mw) AS total_mw
FROM sim.gen_result gr
JOIN network.generator g ON g.id = gr.gen_id
GROUP BY gr.run_id, gr.ts_utc, g.fuel;

-- ============================================
-- 6. Calidad de datos (semáforo de integridad)
-- ============================================
CREATE VIEW analytics.v_data_quality AS
SELECT
    r.id                        AS run_id,
    r.status,
    r.started_at,
    r.finished_at,
    count(DISTINCT br.ts_utc)   AS hours_bus,
    count(DISTINCT gr.ts_utc)   AS hours_gen,
    count(DISTINCT lr.ts_utc)   AS hours_line,
    CASE
        WHEN r.status <> 'ok' THEN 'FAILED'
        WHEN count(DISTINCT br.ts_utc) = 0 THEN 'EMPTY'
        WHEN count(DISTINCT br.ts_utc) <> count(DISTINCT gr.ts_utc)
          OR count(DISTINCT br.ts_utc) <> count(DISTINCT lr.ts_utc)
        THEN 'INCONSISTENT'
        ELSE 'OK'
    END                         AS quality_flag
FROM sim.run r
LEFT JOIN sim.bus_result  br ON br.run_id = r.id
LEFT JOIN sim.gen_result  gr ON gr.run_id = r.id
LEFT JOIN sim.line_result lr ON lr.run_id = r.id
GROUP BY r.id, r.status, r.started_at, r.finished_at;