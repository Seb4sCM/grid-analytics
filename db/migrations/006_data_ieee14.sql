-- ¿Cuántos runs ok vs failed?
SELECT status, count(*) FROM sim.run GROUP BY status;

-- ¿Cuántos escenarios hay de cada tipo?
SELECT
  CASE
    WHEN code LIKE 'n1_line%' THEN 'n1_line'
    WHEN code LIKE 'n1_gen%'  THEN 'n1_gen'
    ELSE code
  END AS tipo,
  count(*)
FROM scenario.scenario
GROUP BY tipo
ORDER BY tipo;