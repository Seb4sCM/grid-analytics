-- ============================================================
-- 02_ranking_contingencias.sql
-- Análisis N-1: impacto de apagar cada línea / generador.
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Ranking de contingencias por coste total
-- ------------------------------------------------------------
SELECT
    s.name                                    AS escenario,
    sum(k.total_cost)::numeric(10,2)          AS coste_dia_usd,
    sum(k.congested)                          AS horas_con_congestion,
    round(max(k.max_lmp)::numeric, 2)         AS lmp_max,
    round((max(k.max_lmp) - min(k.min_lmp))::numeric, 2) AS spread_max
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code LIKE 'n1_%'
GROUP BY s.name
ORDER BY coste_dia_usd DESC;

-- ------------------------------------------------------------
-- 2.2 Sobrecoste vs escenario base (104 161.52 USD)
-- ------------------------------------------------------------
WITH base AS (
    SELECT sum(k.total_cost) AS coste
    FROM sim.kpi k
    JOIN sim.run r           ON r.id = k.run_id
    JOIN scenario.scenario s ON s.id = r.scenario_id
    WHERE s.code = 'base_ieee14'
)
SELECT
    s.name                                                AS escenario,
    sum(k.total_cost)::numeric(10,2)                      AS coste_dia,
    (sum(k.total_cost) - (SELECT coste FROM base))::numeric(10,2) AS sobrecoste_usd,
    round(
        ((sum(k.total_cost) - (SELECT coste FROM base))
         / (SELECT coste FROM base) * 100)::numeric, 3
    )                                                     AS sobrecoste_pct
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code LIKE 'n1_%'
GROUP BY s.name
ORDER BY sobrecoste_usd DESC;

-- ------------------------------------------------------------
-- 2.3 Contingencias sin impacto (coste idéntico al base)
-- ------------------------------------------------------------
WITH base AS (
    SELECT sum(k.total_cost) AS coste
    FROM sim.kpi k
    JOIN sim.run r           ON r.id = k.run_id
    JOIN scenario.scenario s ON s.id = r.scenario_id
    WHERE s.code = 'base_ieee14'
)
SELECT
    s.name              AS escenario,
    sum(k.total_cost)::numeric(10,2) AS coste_dia
FROM sim.kpi k
JOIN sim.run r           ON r.id = k.run_id
JOIN scenario.scenario s ON s.id = r.scenario_id
WHERE s.code LIKE 'n1_%'
GROUP BY s.name
HAVING sum(k.total_cost) = (SELECT coste FROM base)
ORDER BY s.name;