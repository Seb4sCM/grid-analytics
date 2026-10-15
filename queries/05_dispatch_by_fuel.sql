-- ============================================================
-- 05_dispatch_by_fuel.sql
-- Análisis del despacho por tecnología.
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Despacho total por fuel y escenario
-- ------------------------------------------------------------
SELECT
    s.code                      AS escenario,
    g.fuel,
    round(sum(gr.p_mw)::numeric, 2) AS mwh_totales,
    count(DISTINCT g.id)        AS num_generadores_activos
FROM sim.gen_result gr
JOIN sim.run r           ON r.id = gr.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.generator g ON g.id = gr.gen_id
WHERE s.code IN ('base_ieee14', 'line1_out', 'load_x18', 'n1_line_14')
  AND gr.p_mw > 0
GROUP BY s.code, g.fuel
ORDER BY s.code, mwh_totales DESC;

-- ------------------------------------------------------------
-- 5.2 Despacho por generador y escenario
-- ------------------------------------------------------------
SELECT
    s.code                          AS escenario,
    g.id                            AS gen_id,
    g.name,
    g.fuel,
    round(sum(gr.p_mw)::numeric, 2) AS mwh_totales,
    round(avg(gr.p_mw)::numeric, 2) AS mw_promedio,
    round(max(gr.p_mw)::numeric, 2) AS mw_maximo
FROM sim.gen_result gr
JOIN sim.run r           ON r.id = gr.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.generator g ON g.id = gr.gen_id
WHERE s.code IN ('base_ieee14', 'load_x18')
GROUP BY s.code, g.id, g.name, g.fuel
ORDER BY s.code, mwh_totales DESC;

-- ------------------------------------------------------------
-- 5.3 Mix de generación en horas punta vs valle (load_x18)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN extract(hour FROM k.ts_utc AT TIME ZONE 'UTC') BETWEEN 12 AND 16 THEN 'pico (12-16)'
        WHEN extract(hour FROM k.ts_utc AT TIME ZONE 'UTC') BETWEEN 0 AND 5  THEN 'valle (0-5)'
        ELSE 'medio'
    END                         AS franja,
    g.fuel,
    round(avg(gr.p_mw)::numeric, 2) AS mw_promedio
FROM sim.gen_result gr
JOIN sim.run r           ON r.id = gr.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN sim.kpi k           ON k.run_id = gr.run_id AND k.ts_utc = gr.ts_utc
JOIN network.generator g ON g.id = gr.gen_id
WHERE s.code = 'load_x18'
GROUP BY franja, g.fuel
ORDER BY franja, mw_promedio DESC;