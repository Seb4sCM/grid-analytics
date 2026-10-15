# Queries de análisis

Consultas SQL para inspeccionar la base de datos `grid_analytics`.
No forman parte del esquema; son herramientas de análisis y diagnóstico.

## Archivos

| Archivo | Propósito |
|---|---|
| `01_inspect_network.sql` | Inspección de la topología y balance |
| `02_ranking_contingencias.sql` | Ranking de contingencias N-1 |
| `03_lmp_por_nodo.sql` | Análisis de precios nodales (LMP) |
| `04_congestion_por_hora.sql` | Patrón temporal de congestión |
| `05_dispatch_by_fuel.sql` | Despacho por tecnología |
| `06_data_quality_checks.sql` | Verificaciones de integridad |

## Uso

Cada archivo contiene consultas independientes. Ejecutar en pgAdmin
con la base de datos `grid_analytics` seleccionada.

## Hallazgos principales

Ver [`FINDINGS.md`](FINDINGS.md).