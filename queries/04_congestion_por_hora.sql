-- ============================================================
-- 04_congestion_por_hora.sql
-- Patrón temporal de la congestión.
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Congestión por hora en los 4 escenarios principales
-- ------------------------------------------------------------
SELECT
    k.ts_utc,
    s.code,
    k.congested              AS lineas_congestionadas,
    round(k.total_cost::numeric, 2) AS coste_hora
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code IN ('base_ieee14', 'line1_out', 'load_x18', 'n1_line_14')
  AND k.congested > 0
ORDER BY s.code, k.ts_utc;

-- ------------------------------------------------------------
-- 4.2 Horas con más congestión (agregado por escenario)
-- ------------------------------------------------------------
SELECT
    s.code                             AS escenario,
    sum(k.congested)                   AS total_horas_linea_congestionadas,
    count(*) FILTER (WHERE k.congested > 0) AS num_horas_con_congestion,
    max(k.congested)                   AS max_lineas_en_una_hora
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code IN ('base_ieee14', 'line1_out', 'load_x18', 'n1_line_14')
GROUP BY s.code
ORDER BY total_horas_linea_congestionadas DESC;

-- ------------------------------------------------------------
-- 4.3 Hora más crítica de todo el dataset
-- ------------------------------------------------------------
SELECT
    s.code                            AS escenario,
    k.ts_utc,
    k.congested                       AS lineas_congestionadas,
    round(k.total_cost::numeric, 2)   AS coste_hora,
    round(k.max_lmp::numeric, 2)      AS lmp_max_hora
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE k.congested > 0
ORDER BY k.congested DESC, k.total_cost DESC
LIMIT 5;