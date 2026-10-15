from db.connection import get_conn
from psycopg.types.json import Jsonb


def create_run(scenario_id: int, t_start, t_end, config=None) -> int:
    """Inserta una fila en sim.run y devuelve el id."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO sim.run (scenario_id, model, t_start, t_end, config, status)
                VALUES (%s, %s, %s, %s, %s, 'running')
                RETURNING id
            """, (scenario_id, "dc_opf", t_start, t_end, Jsonb(config or {})))
            run_id = cur.fetchone()[0]
        conn.commit()
    return run_id


def save_bus_results(run_id: int, rows: list[tuple]):
    """rows: [(ts_utc, bus_id, angle_rad, lmp_usd_mwh), ...]"""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.executemany("""
                INSERT INTO sim.bus_result (run_id, ts_utc, bus_id, angle_rad, lmp_usd_mwh)
                VALUES (%s, %s, %s, %s, %s)
            """, [(run_id, *r) for r in rows])
        conn.commit()


def save_gen_results(run_id: int, rows: list[tuple]):
    """rows: [(ts_utc, gen_id, p_mw), ...]"""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.executemany("""
                INSERT INTO sim.gen_result (run_id, ts_utc, gen_id, p_mw)
                VALUES (%s, %s, %s, %s)
            """, [(run_id, *r) for r in rows])
        conn.commit()


def save_line_results(run_id: int, rows: list[tuple]):
    """rows: [(ts_utc, line_id, flow_mw, loading_pct), ...]"""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.executemany("""
                INSERT INTO sim.line_result (run_id, ts_utc, line_id, flow_mw, loading_pct)
                VALUES (%s, %s, %s, %s, %s)
            """, [(run_id, *r) for r in rows])
        conn.commit()


def save_kpis(run_id: int, rows: list[tuple]):
    """rows: [(ts_utc, total_cost, max_lmp, min_lmp, congested, renew_share), ...]"""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.executemany("""
                INSERT INTO sim.kpi (run_id, ts_utc, total_cost, max_lmp, min_lmp,
                                     congested, renew_share)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, [(run_id, *r) for r in rows])
        conn.commit()


def finish_run(run_id: int, status: str = "ok"):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE sim.run
                SET status = %s, finished_at = now()
                WHERE id = %s
            """, (status, run_id))
        conn.commit()