# Grid Analytics

Análisis reproducible de una red eléctrica IEEE de 14 buses con Python,
PostgreSQL y Power BI. El proyecto combina optimización de despacho,
simulación de contingencias y análisis de precios nodales.

## Tabla de contenidos

- [Resumen](#resumen)
- [Flujo de trabajo](#flujo-de-trabajo)
- [Tecnologías](#tecnologías)
- [Hallazgos destacados](#hallazgos-destacados)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Reproducir el análisis](#reproducir-el-análisis)
  - [1. Crear la base de datos](#1-crear-la-base-de-datos)
  - [2. Instalar dependencias de Python](#2-instalar-dependencias-de-python)
  - [3. Configurar la conexión](#3-configurar-la-conexión)
  - [4. Crear escenarios](#4-crear-escenarios)
  - [5. Ejecutar simulaciones](#5-ejecutar-simulaciones)
- [Consultas SQL y dashboard](#consultas-sql-y-dashboard)

## Resumen

El proyecto modela la red IEEE 14-bus y evalúa su operación durante un perfil
sintético de demanda de 24 horas. Un modelo DC-OPF determina el despacho de
generación, los flujos por línea y los precios nodales marginales (LMP).
Los escenarios permiten comparar la operación base con cambios en la red y
contingencias N-1.

## Flujo de trabajo

1. Cargar la topología y los datos de la red en PostgreSQL.
2. Generar un perfil diario sintético de demanda.
3. Resolver el DC-OPF para cada hora del escenario.
4. Calcular flujos, despacho, LMP y métricas operativas.
5. Guardar los resultados en PostgreSQL para consultarlos y visualizarlos.
6. Analizar contingencias N-1 de las 20 líneas y los 5 generadores.

El perfil usa una semilla fija (`42`) para que las ejecuciones sean
reproducibles con la misma configuración y los mismos datos.

## Tecnologías

| Tecnología | Uso |
| --- | --- |
| Python 3.10+ | Simulación, optimización y persistencia de resultados |
| NumPy y SciPy | Cálculo numérico y resolución del DC-OPF con `linprog` |
| PostgreSQL | Almacenamiento del modelo de red, escenarios y resultados |
| Psycopg 3 | Conexión entre Python y PostgreSQL |
| Power BI Desktop | Exploración visual de los resultados |

Las versiones de los paquetes de Python están fijadas en
[`requirements.txt`](requirements.txt).

## Hallazgos destacados

Los resultados y el análisis detallado se documentan en
[`queries/FINDINGS.md`](queries/FINDINGS.md). Entre los hallazgos:

- La contingencia del generador hidroeléctrico Gen 4 es la de mayor
  sobrecoste reportado: **15 676 USD/día**.
- Al multiplicar la demanda por 1.8, se observa congestión en **20 de las
  24 horas**.
- La contingencia de la línea 14 deja aislado el Bus 8, que no tiene demanda
  local.
- El coste de operación y las horas de congestión no siempre aumentan juntos;
  son indicadores distintos del impacto de una contingencia.

## Estructura del repositorio

```text
grid-analytics/
├── data/
│   └── ieee14.json                 # Datos de la red IEEE 14-bus en JSON
├── db/
│   └── migrations/                 # Esquemas y carga de datos inicial
│       ├── 001_network.sql
│       ├── 002_timeseries.sql
│       ├── 003_scenarios.sql
│       ├── 004_sim.sql
│       ├── 005_analytics.sql
│       └── 006_data_ieee14.sql
├── powerbi/
│   ├── background.jpg
│   ├── grid-analytics-dashboard.pbix
│   └── *.pdf                       # Export pdf del dashboard
├── python/
│   ├── db/                         # Conexión, carga de red y persistencia
│   ├── ingest/                     # Perfil sintético de demanda
│   ├── scenarios/                  # Modificaciones y contingencias N-1
│   ├── solver/                     # DC-PF y DC-OPF
│   ├── config.py                   # Configuración de conexión a PostgreSQL
│   ├── run_24h.py
│   ├── run_n1_batch.py
│   ├── run_scenario.py
│   └── test_*.py                   # Pruebas del solver y la carga
├── queries/
│   ├── 01_inspect_network.sql
│   ├── 02_ranking_contingencias.sql
│   ├── 03_lmp_por_nodo.sql
│   ├── 04_congestion_por_hora.sql
│   ├── 05_dispatch_by_fuel.sql
│   ├── 06_data_quality_checks.sql
│   ├── FINDINGS.md                 # Resultados e interpretación
│   └── README.md                   # Guía de consultas
├── README.MD
└── requirements.txt
```

## Requisitos

- PostgreSQL 14 o posterior.
- Python 3.10 o posterior.
- Power BI Desktop para abrir el dashboard (opcional).
- `psql` o una herramienta gráfica como pgAdmin para ejecutar las migraciones.

## Reproducir el análisis

### 1. Crear la base de datos

Crea una base de datos vacía:

```sql
CREATE DATABASE grid_analytics;
```

Desde la raíz del repositorio, ejecuta las migraciones en orden:

```powershell
psql -d grid_analytics -f db\migrations\001_network.sql
psql -d grid_analytics -f db\migrations\002_timeseries.sql
psql -d grid_analytics -f db\migrations\003_scenarios.sql
psql -d grid_analytics -f db\migrations\004_sim.sql
psql -d grid_analytics -f db\migrations\005_analytics.sql
psql -d grid_analytics -f db\migrations\006_data_ieee14.sql
```

La migración `006_data_ieee14.sql` carga los datos iniciales de la red.
El archivo [`data/ieee14.json`](data/ieee14.json) contiene la representación
JSON de esa red.

### 2. Instalar dependencias de Python

Crea y activa un entorno virtual desde la raíz del repositorio.

**Windows (PowerShell):**

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

**Linux o macOS:**

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

### 3. Configurar la conexión

La configuración está en [`python/config.py`](python/config.py). La conexión
lee estas variables de entorno:

| Variable | Valor predeterminado | Descripción |
| --- | --- | --- |
| `GRID_DB_NAME` | `grid_analytics` | Nombre de la base de datos |
| `GRID_DB_USER` | `postgres` | Usuario de PostgreSQL |
| `GRID_DB_PASS` | vacío | Contraseña |
| `GRID_DB_HOST` | `localhost` | Host de PostgreSQL |
| `GRID_DB_PORT` | `5432` | Puerto de PostgreSQL |

Configura la contraseña en la sesión de terminal donde ejecutarás los scripts.

**Windows (PowerShell):**

```powershell
$env:GRID_DB_PASS = "tu_password"
```

**Linux o macOS:**

```bash
export GRID_DB_PASS="tu_password"
```

Si tu instalación usa otros valores de conexión, configura también las
variables correspondientes antes de ejecutar los scripts.

### 4. Crear escenarios

Para reproducir los ejemplos, registra un escenario base, uno con la línea 1
fuera de servicio y otro con la demanda multiplicada por 1.8. Ejecuta este
bloque una sola vez en la base recién creada:

```sql
WITH
base_scenario AS (
    INSERT INTO scenario.scenario (code, name, description, base_net)
    VALUES ('base_ieee14', 'IEEE 14-bus base', 'Caso base sin modificaciones', 'ieee14')
    RETURNING id, code
),
line_scenario AS (
    INSERT INTO scenario.scenario (code, name, description, base_net)
    VALUES ('line1_out', 'Sin línea 1', 'Línea 1 fuera de servicio', 'ieee14')
    RETURNING id, code
),
load_scenario AS (
    INSERT INTO scenario.scenario (code, name, description, base_net)
    VALUES ('load_x18', 'Demanda ×1.8', 'Demanda escalada al 180%', 'ieee14')
    RETURNING id, code
),
line_modification AS (
    INSERT INTO scenario.modification (scenario_id, op, target_id, note)
    SELECT id, 'line_out', 1, 'Línea 1 fuera'
    FROM line_scenario
    RETURNING scenario_id
),
load_modification AS (
    INSERT INTO scenario.modification (scenario_id, op, target_id, payload, note)
    SELECT id, 'load_scale', NULL, '{"factor": 1.8}'::jsonb, 'Demanda ×1.8'
    FROM load_scenario
    RETURNING scenario_id
)
SELECT id, code FROM base_scenario
UNION ALL
SELECT id, code FROM line_scenario
UNION ALL
SELECT id, code FROM load_scenario
ORDER BY code;
```

Guarda los identificadores devueltos: los necesitarás para ejecutar cada
escenario. Puedes volver a consultarlos con:

```sql
SELECT id, code
FROM scenario.scenario
WHERE code IN ('base_ieee14', 'line1_out', 'load_x18')
ORDER BY code;
```

### 5. Ejecutar simulaciones

Los scripts se ejecutan desde el directorio `python/`, con el entorno virtual
activado y las variables de conexión configuradas. Sustituye `<ID>` por el
identificador obtenido para el escenario:

```powershell
cd python
python run_scenario.py <ID>
```

Ejecuta el comando para cada escenario que quieras analizar. Cada ejecución
resuelve 24 horas y guarda los resultados en PostgreSQL.

Para generar y simular el lote de contingencias N-1 (20 líneas y
5 generadores):

```powershell
python run_n1_batch.py
```

## Consultas SQL y dashboard

Las consultas de inspección de red, ranking de contingencias, LMP, congestión,
despacho por combustible y calidad de datos están en [`queries/`](queries/).
Consulta [`queries/README.md`](queries/README.md) para su descripción y
[`queries/FINDINGS.md`](queries/FINDINGS.md) para los resultados interpretados.

El dashboard de Power BI está disponible en
[`powerbi/grid-analytics-dashboard.pbix`](powerbi/grid-analytics-dashboard.pbix).
