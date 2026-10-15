from db.connection import get_conn


def load_buses() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, name, kv, lat, lon, region, is_slack
                FROM network.bus
                ORDER BY id
            """)
            cols = [c.name for c in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]


def load_generators() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, bus_id, name, fuel, p_max_mw, p_min_mw,
                       cost_a, cost_b, cost_c
                FROM network.generator
                ORDER BY id
            """)
            cols = [c.name for c in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]


def load_lines() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, from_bus, to_bus, r_pu, x_pu, s_max_mva
                FROM network.line
                ORDER BY id
            """)
            cols = [c.name for c in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]


def load_loads() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, bus_id, name, p_nom_mw
                FROM network.load
                ORDER BY id
            """)
            cols = [c.name for c in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]


def load_network() -> dict:
    """Carga toda la red en un diccionario."""
    return {
        "buses":      load_buses(),
        "generators": load_generators(),
        "lines":      load_lines(),
        "loads":      load_loads(),
    }