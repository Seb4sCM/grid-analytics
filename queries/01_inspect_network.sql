-- ============================================================
-- 01_inspect_network.sql
-- Inspección básica de la topología y balance de la red.
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Conteo de entidades
-- ------------------------------------------------------------
SELECT 'bus' AS entidad, count(*) AS total FROM network.bus
UNION ALL SELECT 'generator', count(*) FROM network.generator
UNION ALL SELECT 'line',      count(*) FROM network.line
UNION ALL SELECT 'load',      count(*) FROM network.load;

-- ------------------------------------------------------------
-- 1.2 Grado de cada nodo (número de líneas conectadas)
-- ------------------------------------------------------------
SELECT
    b.id,
    b.name,
    count(l.id) AS num_lineas
FROM network.bus b
LEFT JOIN network.line l
    ON l.from_bus = b.id OR l.to_bus = b.id
GROUP BY b.id, b.name
ORDER BY num_lineas DESC;

-- ------------------------------------------------------------
-- 1.3 Capacidad de generación vs demanda nominal
-- ------------------------------------------------------------
SELECT
    (SELECT sum(p_max_mw) FROM network.generator) AS gen_max_total_mw,
    (SELECT sum(p_nom_mw) FROM network.load)      AS demanda_total_mw,
    (SELECT sum(p_max_mw) FROM network.generator)
      - (SELECT sum(p_nom_mw) FROM network.load)  AS margen_mw;

-- ------------------------------------------------------------
-- 1.4 Generadores por tecnología
-- ------------------------------------------------------------
SELECT
    fuel,
    count(*)        AS num_generadores,
    sum(p_max_mw)   AS capacidad_total_mw
FROM network.generator
GROUP BY fuel
ORDER BY capacidad_total_mw DESC;