-- ============================================
-- 001_network.sql
-- Esquema de topología de la red eléctrica
-- ============================================

CREATE SCHEMA IF NOT EXISTS network;

-- Nodos (buses)
CREATE TABLE network.bus (
    id          int PRIMARY KEY,
    name        text NOT NULL UNIQUE,
    kv          numeric(6,2) NOT NULL,
    lat         numeric(9,6),
    lon         numeric(9,6),
    region      text,
    is_slack    boolean NOT NULL DEFAULT false
);

-- Generadores
CREATE TABLE network.generator (
    id          int PRIMARY KEY,
    bus_id      int NOT NULL REFERENCES network.bus(id),
    name        text NOT NULL,
    fuel        text NOT NULL
                CHECK (fuel IN ('gas','coal','hydro','nuclear','wind','solar','other')),
    p_max_mw    numeric(10,2) NOT NULL,
    p_min_mw    numeric(10,2) NOT NULL DEFAULT 0,
    cost_a      numeric(10,4) NOT NULL DEFAULT 0,
    cost_b      numeric(10,4) NOT NULL,
    cost_c      numeric(10,2) NOT NULL DEFAULT 0,
    CHECK (p_min_mw <= p_max_mw)
);

-- Líneas de transmisión
CREATE TABLE network.line (
    id          int PRIMARY KEY,
    from_bus    int NOT NULL REFERENCES network.bus(id),
    to_bus      int NOT NULL REFERENCES network.bus(id),
    r_pu        numeric(10,6) NOT NULL,
    x_pu        numeric(10,6) NOT NULL,
    s_max_mva   numeric(10,2) NOT NULL,
    CHECK (from_bus <> to_bus)
);

-- Cargas (demanda)
CREATE TABLE network.load (
    id          int PRIMARY KEY,
    bus_id      int NOT NULL REFERENCES network.bus(id),
    name        text NOT NULL,
    p_nom_mw    numeric(10,2) NOT NULL
);