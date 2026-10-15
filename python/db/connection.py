from contextlib import contextmanager
import psycopg
from config import DB_CONFIG


@contextmanager
def get_conn():
    """Devuelve una conexión a PostgreSQL que se cierra sola."""
    conn = psycopg.connect(**DB_CONFIG)
    try:
        yield conn
    finally:
        conn.close()
        