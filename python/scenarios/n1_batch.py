from db.connection import get_conn


def create_contingency_scenario(kind: str, target_id: int, target_name: str) -> int:
    """
    Crea un escenario N-1 si no existe.
    kind: 'line' o 'gen'
    Devuelve el scenario_id.
    """
    code = f"n1_{kind}_{target_id}"

    with get_conn() as conn:
        with conn.cursor() as cur:
            # ¿Ya existe?
            cur.execute(
                "SELECT id FROM scenario.scenario WHERE code = %s",
                (code,)
            )
            row = cur.fetchone()
            if row:
                return row[0]

            # Crear escenario
            cur.execute("""
                INSERT INTO scenario.scenario (code, name, description, base_net)
                VALUES (%s, %s, %s, 'ieee14')
                RETURNING id
            """, (
                code,
                f"N-1: {kind} {target_id} out",
                f"Contingencia N-1 apagando {kind} {target_id} ({target_name})",
            ))
            scenario_id = cur.fetchone()[0]

            # Crear modificación
            op = "line_out" if kind == "line" else "gen_out"
            cur.execute("""
                INSERT INTO scenario.modification (scenario_id, op, target_id, note)
                VALUES (%s, %s, %s, %s)
            """, (scenario_id, op, target_id, f"{kind} {target_id} out"))

        conn.commit()

    return scenario_id


def list_all_lines_and_gens() -> list[tuple]:
    """Devuelve [(kind, id, name), ...] para todas las líneas y generadores."""
    items = []
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, from_bus, to_bus FROM network.line ORDER BY id")
            for lid, fb, tb in cur.fetchall():
                items.append(("line", lid, f"Bus{fb}-Bus{tb}"))

            cur.execute("SELECT id, name FROM network.generator ORDER BY id")
            for gid, gname in cur.fetchall():
                items.append(("gen", gid, gname))

    return items