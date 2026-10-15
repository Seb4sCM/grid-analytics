import numpy as np


def build_B(lines: list[dict], bus_ids: list[int]) -> np.ndarray:
    """
    Construye la matriz de susceptancias B (NxN).
    B[i,i] = suma de 1/x de líneas conectadas al bus i
    B[i,j] = -1/x de la línea entre i y j
    """
    n = len(bus_ids)
    idx = {bid: k for k, bid in enumerate(bus_ids)}
    B = np.zeros((n, n))

    for line in lines:
        i = idx[line["from_bus"]]
        j = idx[line["to_bus"]]
        x = float(line["x_pu"])
        b = 1.0 / x

        B[i, i] += b
        B[j, j] += b
        B[i, j] -= b
        B[j, i] -= b

    return B


def build_P(net: dict, bus_ids: list[int]) -> np.ndarray:
    """
    Construye el vector de inyección neta P (MW).
    P = generación - demanda  (por nodo)
    """
    n = len(bus_ids)
    idx = {bid: k for k, bid in enumerate(bus_ids)}
    P = np.zeros(n)

    for g in net["generators"]:
        P[idx[g["bus_id"]]] += float(g["p_max_mw"])

    for load in net["loads"]:
        P[idx[load["bus_id"]]] -= float(load["p_nom_mw"])

    return P


def solve_dc_pf(net: dict) -> dict:
    """
    Resuelve DC power flow para la red completa.
    Devuelve ángulos por bus y flujos por línea.
    """
    buses = net["buses"]
    bus_ids = [b["id"] for b in buses]
    idx = {bid: k for k, bid in enumerate(bus_ids)}
    n = len(bus_ids)

    # Slack
    slack_pos = next(k for k, b in enumerate(buses) if b["is_slack"])

    # Matriz B y vector P
    B = build_B(net["lines"], bus_ids)
    P = build_P(net, bus_ids)

    # Eliminar fila/columna del slack
    keep = [k for k in range(n) if k != slack_pos]
    B_red = B[np.ix_(keep, keep)]
    P_red = P[keep]

    # Resolver B_red · theta_red = P_red
    theta_red = np.linalg.solve(B_red, P_red)

    # Reconstruir theta completo (slack = 0)
    theta = np.zeros(n)
    for pos, k in enumerate(keep):
        theta[k] = theta_red[pos]

    # Flujos por línea
    flows = {}
    for line in net["lines"]:
        i = idx[line["from_bus"]]
        j = idx[line["to_bus"]]
        x = float(line["x_pu"])
        flows[line["id"]] = (theta[i] - theta[j]) / x

    return {
        "bus_ids": bus_ids,
        "theta":   theta,
        "flows":   flows,
    }