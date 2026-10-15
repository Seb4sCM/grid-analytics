import numpy as np
from scipy.optimize import linprog


# Base del sistema por unidad (MVA). Convención estándar.
BASE_MVA = 100.0


def solve_dc_opf(net: dict, demand_factor: float = 1.0) -> dict:
    """
    DC-OPF con costes lineales, en sistema por unidad (p.u.) internamente.

    Variables: x = [p_g (G), theta_n (N)]     -- p_g en p.u., theta en rad
    Objetivo:  min sum(cost_b_g * p_g)         -- cost_b en USD/MWh
    Balance:   B · theta = P                    -- B, P en p.u.

    Convención: todas las magnitudes internas (P, límites, flujos) en p.u.
    Solo en los bordes se convierte a MW / MVA.
    """
    buses = net["buses"]
    gens = net["generators"]
    lines = net["lines"]
    loads = net["loads"]

    N = len(buses)
    G = len(gens)
    L = len(lines)

    bus_ids = [b["id"] for b in buses]
    bus_idx = {bid: k for k, bid in enumerate(bus_ids)}
    slack_pos = next(k for k, b in enumerate(buses) if b["is_slack"])

    n_var = G + N

    def p_pos(g):  return g
    def th_pos(b): return G + b

    # ----------------------------------------
    # Objetivo: min sum(cost_b_g * p_g)
    # cost_b está en USD/MWh, p_g en p.u.
    # Multiplicamos por BASE_MVA para que el objetivo
    # esté en USD/h cuando p_g esté en p.u.
    # ----------------------------------------
    c = np.zeros(n_var)
    for g, gen in enumerate(gens):
        c[p_pos(g)] = float(gen["cost_b"]) * BASE_MVA

    # ----------------------------------------
    # Demanda por bus, en p.u.
    # ----------------------------------------
    demand = np.zeros(N)
    for load in loads:
        demand[bus_idx[load["bus_id"]]] += float(load["p_nom_mw"]) * demand_factor / BASE_MVA

    # ----------------------------------------
    # Matriz B (susceptancias), ya en p.u.
    # ----------------------------------------
    B = np.zeros((N, N))
    for line in lines:
        i = bus_idx[line["from_bus"]]
        j = bus_idx[line["to_bus"]]
        b = 1.0 / float(line["x_pu"])
        B[i, i] += b
        B[j, j] += b
        B[i, j] -= b
        B[j, i] -= b

    # ----------------------------------------
    # Restricciones de igualdad: balance nodal
    # Para cada bus b:
    #   sum_g pertenece b p_g  -  sum_k B[b,k] · theta_k  =  demand_b     (todo en p.u.)
    # Slack: theta_slack = 0
    # ----------------------------------------
    A_eq = np.zeros((N + 1, n_var))
    b_eq = np.zeros(N + 1)

    for b in range(N):
        for g, gen in enumerate(gens):
            if bus_idx[gen["bus_id"]] == b:
                A_eq[b, p_pos(g)] = 1.0
        for k in range(N):
            A_eq[b, th_pos(k)] = -B[b, k]
        b_eq[b] = demand[b]

    A_eq[N, th_pos(slack_pos)] = 1.0
    b_eq[N] = 0.0

    # ----------------------------------------
    # Cotas de variables
    # p_g en p.u.  -  convertir p_min, p_max
    # θ libre
    # ----------------------------------------
    bounds = []
    for gen in gens:
        p_min_pu = float(gen["p_min_mw"]) / BASE_MVA
        p_max_pu = float(gen["p_max_mw"]) / BASE_MVA
        bounds.append((p_min_pu, p_max_pu))
    for _ in range(N):
        bounds.append((None, None))

    # ----------------------------------------
    # Límites de línea
    # Flujo f_pu = (θ_i - θ_j) / x_pu      [p.u.]
    # Restricción: |f_pu| <= s_max_mva / BASE_MVA
    # ----------------------------------------
    A_ub = np.zeros((2 * L, n_var))
    b_ub = np.zeros(2 * L)

    for l, line in enumerate(lines):
        i = bus_idx[line["from_bus"]]
        j = bus_idx[line["to_bus"]]
        x_pu = float(line["x_pu"])
        s_max_pu = float(line["s_max_mva"]) / BASE_MVA

        # f_pu = (θ_i - θ_j) / x_pu
        A_ub[2 * l, th_pos(i)] =  1.0 / x_pu
        A_ub[2 * l, th_pos(j)] = -1.0 / x_pu
        b_ub[2 * l] = s_max_pu

        A_ub[2 * l + 1, th_pos(i)] = -1.0 / x_pu
        A_ub[2 * l + 1, th_pos(j)] =  1.0 / x_pu
        b_ub[2 * l + 1] = s_max_pu

    # ----------------------------------------
    # Resolver
    # ----------------------------------------
    res = linprog(c, A_ub=A_ub, b_ub=b_ub, A_eq=A_eq, b_eq=b_eq,
                  bounds=bounds, method="highs")

    if not res.success:
        raise RuntimeError(f"OPF no convergió: {res.message}")

    # ----------------------------------------
    # Extraer resultados
    # x contiene: p (p.u.), Theta (rad)
    # Convertir a unidades físicas para el retorno.
    # ----------------------------------------
    x = res.x
    p_pu = x[:G]
    theta = x[G:]

    p_mw = p_pu * BASE_MVA

    # Flujos: f_pu = (theta_i - theta_j)/x_pu  -  f_MW = f_pu · BASE_MVA
    flows_mw = {}
    for line in lines:
        i = bus_idx[line["from_bus"]]
        j = bus_idx[line["to_bus"]]
        x_pu = float(line["x_pu"])
        flows_mw[line["id"]] = (theta[i] - theta[j]) / x_pu * BASE_MVA

    # LMP: dual del balance nodal.
    # El dual está en USD/h por unidad de b_eq (que está en p.u.).
    # Como b_eq está en p.u., el dual está en USD/(h·p.u.) = USD/(h · MW/100) = 100 · USD/MWh.
    # Multiplicamos por BASE_MVA para obtener USD/MWh.
    lmp = res.eqlin.marginals[:N] / BASE_MVA

    # Coste total: c·x ya está en USD/h (porque escalamos c por BASE_MVA).
    cost_usd_h = res.fun

    return {
        "bus_ids": bus_ids,
        "gen_ids": [g["id"] for g in gens],
        "p":       p_mw,          # MW
        "theta":   theta,         # rad
        "flows":   flows_mw,      # MW
        "lmp":     lmp,           # USD/MWh
        "cost":    cost_usd_h,    # USD/h
        "status":  res.status,
    }