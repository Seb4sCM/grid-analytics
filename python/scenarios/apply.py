from db.connection import get_conn


def load_modifications(scenario_id: int) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT op, target_id, payload
                FROM scenario.modification
                WHERE scenario_id = %s
                ORDER BY id
            """, (scenario_id,))
            cols = [c.name for c in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]


def apply_modifications(net: dict, mods: list[dict]) -> dict:
    """
    Devuelve una copia de la red con las modificaciones aplicadas.
    No muta la red original.
    """
    import copy
    net2 = copy.deepcopy(net)

    for m in mods:
        op = m["op"]

        if op == "line_out":
            lid = m["target_id"]
            net2["lines"] = [l for l in net2["lines"] if l["id"] != lid]

        elif op == "gen_out":
            gid = m["target_id"]
            net2["generators"] = [g for g in net2["generators"] if g["id"] != gid]

        elif op == "load_scale":
            factor = float(m["payload"]["factor"])
            for load in net2["loads"]:
                load["p_nom_mw"] = float(load["p_nom_mw"]) * factor
        else:
            raise ValueError(f"Operación desconocida: {op}")

    return net2


def load_scenario_network(scenario_id: int, base_net: dict) -> dict:
    """Carga la red base, aplica las modificaciones del escenario, y devuelve la red resultante."""
    mods = load_modifications(scenario_id)
    return apply_modifications(base_net, mods)