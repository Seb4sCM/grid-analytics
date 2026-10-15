# Hallazgos principales

Análisis sobre la red IEEE 14-bus con escenarios base, N-1 (20 líneas + 
5 generadores) y sobrecarga de demanda (×1.8). Todas las cifras están 
respaldadas por las consultas en este directorio.

## 1. La generación es más crítica que la transmisión

Apagar generadores cuesta más que apagar líneas:

| Contingencia | Sobrecoste (USD/día) | Horas congestión |
|---|---|---|
| `n1_gen_4` (hydro) | **+15 676** | 13 |
| `n1_gen_1` (gas slack) | +9 484 | 0 |
| `n1_gen_3` (coal) | +6 846 | 17 |
| `n1_line_1` | +14 | 6 |
| `n1_line_2` | +14 | 6 |
| 20 líneas restantes | 0 | 0 |

**Implicación**: la red tiene redundancia suficiente en transmisión. La 
generación es el verdadero cuello de botella.

## 2. El coste de sustitución determina el impacto

El Gen 4 (hydro, 12 USD/MWh) es el más crítico porque sustituirlo requiere 
gas a 20-30 USD/MWh. Diferencia: +8 a +18 USD/MWh.
El Gen 3 (coal, 18 USD/MWh) se sustituye por gas (20 USD/MWh), solo +2 USD/MWh.

**Implicación**: el impacto de una contingencia depende del **coste de 
sustitución**, no del volumen de MW perdidos.

## 3. La demanda ×1.8 fragmenta el mercado

Con demanda normal, todos los nodos tienen el mismo LMP (sistema "cobre").
Con demanda ×1.8 (`load_x18`):

- Congestión en **20 de 24 horas**.
- Spread LMP sube de **0.00 a 12.75 USD/MWh**.
- El Bus 2 se convierte en el más caro (LMP medio 26.22 USD/MWh).

**Implicación**: la red está dimensionada para la demanda base pero no 
para picos. El sistema opera cerca del límite térmico.

## 4. Nodo aislado: caso `n1_line_14`

Al apagar la línea 14 (Bus 7 <-> Bus 8):

- El Bus 8 queda desconectado del resto de la red.
- El Bus 8 no tiene demanda local.
- Su LMP cae a **0 USD/MWh** durante las 24 horas.
- El spread artificial sube a 20 USD/MWh (20 - 0).

**Implicación**: el análisis N-1 detecta **islas eléctricas** que no son 
evidentes desde la topología nominal. Es un hallazgo cualitativo, no solo 
cuantitativo.

## 5. Congestión ≠ coste

Dos escenarios con firmas opuestas:

- `n1_gen_1` (apagar gas del slack): **+9 484 USD/día** con **0 horas** de congestión.
- `n1_line_1` (apagar línea 1): **+14 USD/día** con **6 horas** de congestión.

**Implicación**: coste y congestión son dimensiones ortogonales. Un sistema 
puede ser caro sin estar congestionado, y congestionado sin ser caro.

## 6. Merit order visible en el tiempo

El precio del sistema cambia de régimen según la demanda:

- **Valle (0-5h)**: coal marginal → LMP = 18 USD/MWh.
- **Pico (12-16h)**: gas marginal → LMP = 20-32.75 USD/MWh.

El gas absorbe toda la variabilidad:
- Valle: 55 MW promedio.
- Pico: 117 MW promedio.

Coal y hydro van a `p_max` en todas las horas (100 y 80 MW).

**Implicación**: el LMP no es continuo. Cambia por **discontinuidades del 
despacho económico**. El Gen 5 (gas caro, 30 USD/MWh) solo entra cuando 
Gen 2 se satura, y su entrada dispara el LMP a 32.75.

## 7. El Bus 1 es estructuralmente el más barato

En todos los escenarios, el Bus 1 tiene el LMP más bajo o igual al resto:

| Escenario | Bus 1 (medio) | Resto (medio) |
|---|---|---|
| base_ieee14 | 19.917 | 19.917 |
| line1_out | 19.917 | 20.333 |
| load_x18 | 20.000 | 24.2 - 26.2 |
| n1_line_14 | 19.917 | 19.917 (Bus 8 = 0) |

**Implicación**: el Bus 1 alberga el slack con generación local (Gen 1, gas 
a 20 USD/MWh). Cuando hay congestión, su generador local fija su precio. 
No depende de importar energía del resto de la red.

## 8. La línea 1 es el corredor crítico

En el caso base, la línea 1 (Bus 1 ↔ Bus 2) ya opera al 71.6% de su límite 
en horas punta. Es la línea más cargada del sistema (93 MW en pico, frente 
a 50 MW de la siguiente).

En `load_x18`, la línea 1 se congestiona 20 de 24 horas. Apagarla (`line1_out`) 
redirige el flujo y congestiona otra línea en las mismas horas pico.

**Implicación**: es el cuello de botella físico del sistema. Cualquier 
inversión de refuerzo debería empezar aquí.

## 9. Distribución espacial de precios en `load_x18`

LMP medio por región:

| Región | LMP medio | LMP max | Nodos |
|---|---|---|---|
| sur | 24.815 | 30.000 | 5 |
| este | 24.726 | 29.793 | 4 |
| central | **24.248** | **32.750** | 5 |

La región `central` tiene el mayor pico (por el Bus 2, 32.75) pero el menor 
promedio (por el Bus 1, siempre a 20).

**Implicación**: la congestión no afecta uniformemente. Los nodos con 
generación local barata mantienen precios bajos incluso en horas punta.

## 10. Calidad de datos: el pipeline es reproducible

Verificaciones finales del dataset:

- **28 runs** con `status = 'ok'`.
- **24 horas** por run en todas las tablas (`bus_result`, `gen_result`, `line_result`).
- **0 violaciones** de límites de generación (ni negativos, ni excedidos).
- **1 nodo aislado** detectado (`n1_line_14` / Bus 8).
- **Vista `v_data_quality`** con `quality_flag = 'OK'` en los 28 runs.

**Implicación**: el pipeline es determinista y auditable. Cualquier 
reproducción con las mismas semillas produce los mismos resultados.

## 11. Contingencias con impacto cero

20 de las 25 contingencias N-1 (todas de líneas excepto la 1 y la 2) tienen 
coste idéntico al base. La red tiene una **redundancia topológica alta** para 
el nivel de demanda actual.

Solo hay **2 líneas** y **3 generadores** críticos. El resto es ruido.

**Implicación**: priorizar inversiones con este ranking evita gasto en 
elementos que no aportan resiliencia marginal.