-- ============================================================
-- 06_data_quality_checks.sql
-- Verificaciones de integridad de los datos de simulación.
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Estado de todas las corridas
-- ------------------------------------------------------------
SELECT status, count(*) AS num_runs
FROM sim.run
GROUP BY status;

-- ------------------------------------------------------------
-- 6.2 Calidad por run (desde la vista de analytics)
-- ------------------------------------------------------------
SELECT
    run_id,
    status,
    hours_bus,
    hours_gen,
    hours_line,
    quality_flag
FROM analytics.v_data_quality
ORDER BY run_id;

-- ------------------------------------------------------------
-- 6.3 Cobertura de horas por escenario (24h esperadas)
-- ------------------------------------------------------------
SELECT
    s.code,
    count(DISTINCT k.ts_utc) AS horas_kpi,
    min(k.ts_utc)            AS primera_hora,
    max(k.ts_utc)            AS ultima_hora
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
GROUP BY s.code
ORDER BY s.code;

-- ------------------------------------------------------------
-- 6.4 Detección de violaciones de balance
-- (generación total ≠ demanda total en DC-OPF)
-- ------------------------------------------------------------
WITH gen_tot AS (
    SELECT run_id, ts_utc, sum(p_mw) AS gen_total
    FROM sim.gen_result
    GROUP BY run_id, ts_utc
),
dem_tot AS (
    SELECT
        k.run_id,
        k.ts_utc,
        sum(l.p_nom_mw) AS dem_total
    FROM sim.kpi k
    CROSS JOIN network.load l
    GROUP BY k.run_id, k.ts_utc
)
SELECT
    g.run_id,
    g.ts_utc,
    round(g.gen_total::numeric, 2)  AS gen_mw,
    round(d.dem_total::numeric, 2)  AS dem_mw,
    round((g.gen_total - d.dem_total)::numeric, 2) AS diff
FROM gen_tot g
JOIN dem_tot d ON d.run_id = g.run_id AND d.ts_utc = g.ts_utc
WHERE abs(g.gen_total - d.dem_total) > 0.1
ORDER BY g.run_id, g.ts_utc
LIMIT 20;

-- ------------------------------------------------------------
-- 6.5 Nodos aislados (LMP = 0)
-- ------------------------------------------------------------
SELECT
    s.code       AS escenario,
    br.bus_id,
    b.name       AS bus_name,
    count(*)     AS num_horas_aislado
FROM sim.bus_result br
JOIN sim.run r           ON r.id = br.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.bus b       ON b.id = br.bus_id
WHERE br.lmp_usd_mwh = 0
GROUP BY s.code, br.bus_id, b.name
ORDER BY s.code, br.bus_id;