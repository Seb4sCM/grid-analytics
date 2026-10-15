import numpy as np


def daily_demand_profile(hours: int = 24, seed: int = 42) -> np.ndarray:
    """
    Perfil diario de demanda normalizado (media = 1.0).

    Forma:
      - Valle nocturno (0-6h): ~0.65
      - Pico mañana (7-9h):    ~0.95
      - Valle medio (10-17h):  ~0.85
      - Pico tarde (18-22h):   ~1.15
      - Caída (23h):           ~0.75

    Añade ruido leve reproducible.
    """
    rng = np.random.default_rng(seed)
    h = np.arange(hours)

    # Componente diario principal: pico a las 14h y a las 20h
    base = 1.0
    daily = 0.15 * np.sin(2 * np.pi * (h - 8) / 24)          # pico matinal
    evening = 0.20 * np.exp(-((h - 20) ** 2) / 8.0)           # pico tarde
    night = -0.15 * np.exp(-((h - 3) ** 2) / 8.0)             # valle nocturno

    profile = base + daily + evening + night

    # Ruido leve reproducible
    noise = rng.normal(0, 0.02, hours)
    profile = profile + noise

    # Normalizar a media 1.0
    profile = profile / profile.mean()

    return profile