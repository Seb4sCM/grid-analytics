-- ============================================================
-- 03_lmp_por_nodo.sql
-- Análisis de precios nodales (LMP).
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 LMP medio, min y max por nodo y escenario
-- ------------------------------------------------------------
SELECT
    s.code                       AS escenario,
    br.bus_id,
    b.name                       AS bus_name,
    b.region,
    round(avg(br.lmp_usd_mwh)::numeric, 3)  AS lmp_medio,
    round(max(br.lmp_usd_mwh)::numeric, 3)  AS lmp_max,
    round(min(br.lmp_usd_mwh)::numeric, 3)  AS lmp_min
FROM sim.bus_result br
JOIN sim.run r           ON r.id = br.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.bus b       ON b.id = br.bus_id
WHERE s.code IN ('base_ieee14', 'line1_out', 'load_x18', 'n1_line_14')
GROUP BY s.code, br.bus_id, b.name, b.region
ORDER BY s.code, lmp_medio DESC;

-- ------------------------------------------------------------
-- 3.2 Spread de LMP por escenario (max - min entre nodos)
-- ------------------------------------------------------------
SELECT
    s.code                                       AS escenario,
    round(avg(k.max_lmp - k.min_lmp)::numeric, 3) AS spread_medio,
    round(max(k.max_lmp - k.min_lmp)::numeric, 3) AS spread_max
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code IN ('base_ieee14', 'line1_out', 'load_x18', 'n1_line_14')
GROUP BY s.code
ORDER BY spread_max DESC;

-- ------------------------------------------------------------
-- 3.3 Nodos aislados (LMP = 0 en alguna hora)
-- ------------------------------------------------------------
SELECT DISTINCT
    s.code       AS escenario,
    br.bus_id,
    b.name       AS bus_name
FROM sim.bus_result br
JOIN sim.run r           ON r.id = br.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.bus b       ON b.id = br.bus_id
WHERE br.lmp_usd_mwh = 0
ORDER BY s.code, br.bus_id;

-- ------------------------------------------------------------
-- 3.4 Distribución del LMP por región en el escenario más estresado
-- ------------------------------------------------------------
SELECT
    b.region,
    round(avg(br.lmp_usd_mwh)::numeric, 3) AS lmp_medio,
    round(max(br.lmp_usd_mwh)::numeric, 3) AS lmp_max,
    round(min(br.lmp_usd_mwh)::numeric, 3) AS lmp_min,
    count(DISTINCT br.bus_id)              AS num_nodos
FROM sim.bus_result br
JOIN sim.run r           ON r.id = br.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
JOIN network.bus b       ON b.id = br.bus_id
WHERE s.code = 'load_x18'
GROUP BY b.region
ORDER BY lmp_medio DESC;