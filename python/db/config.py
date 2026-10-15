import os

DB_CONFIG = {
    "dbname":   os.getenv("GRID_DB_NAME", "grid_analytics"),
    "user":     os.getenv("GRID_DB_USER", "postgres"),
    "password": os.getenv("GRID_DB_PASS", ""),
    "host":     os.getenv("GRID_DB_HOST", "localhost"),
    "port":     os.getenv("GRID_DB_PORT", "5432"),
}