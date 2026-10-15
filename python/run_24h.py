from datetime import datetime, timezone, timedelta

from db.load_network import load_network
from db.save_results import (
    create_run, save_bus_results, save_gen_results,
    save_line_results, save_kpis, finish_run,
)
from solver.dc_opf import solve_dc_opf
from ingest.synthetic_profile import daily_demand_profile


SCENARIO_ID = 1            
RUN_DATE    = datetime(2024, 1, 15, 0, 0, tzinfo=timezone.utc)
HOURS       = 24


def main():
    net = load_network()
    profile = daily_demand_profile(hours=HOURS, seed=42)

    t_start = RUN_DATE
    t_end   = RUN_DATE + timedelta(hours=HOURS)

    run_id = create_run(
        scenario_id=SCENARIO_ID,
        t_start=t_start,
        t_end=t_end,
        config={"profile": "daily_synthetic", "seed": 42, "hours": HOURS},
    )
    print(f"Run creado: id={run_id}")

    bus_rows, gen_rows, line_rows, kpi_rows = [], [], [], []

    for h in range(HOURS):
        ts = RUN_DATE + timedelta(hours=h)
        factor = float(profile[h])

        result = solve_dc_opf(net, demand_factor=factor)

        # Nodos
        for bid, th, lmp in zip(result["bus_ids"], result["theta"], result["lmp"]):
            bus_rows.append((ts, bid, th, lmp))

        # Generadores
        for gid, p in zip(result["gen_ids"], result["p"]):
            gen_rows.append((ts, gid, p))

        # Líneas
        for line in net["lines"]:
            lid = line["id"]
            flow = result["flows"][lid]
            s_max = float(line["s_max_mva"])
            loading = abs(flow) / s_max * 100.0
            line_rows.append((ts, lid, flow, loading))

        # KPIs
        total_cost = result["cost"]
        max_lmp = float(max(result["lmp"]))
        min_lmp = float(min(result["lmp"]))
        congested = sum(1 for r in line_rows if r[0] == ts and r[3] > 90)
        renew_share = 0.0  # lo rellenamos cuando tengamos perfiles por fuel
        kpi_rows.append((ts, total_cost, max_lmp, min_lmp, congested, renew_share))

        print(f"  {ts.isoformat()}  factor={factor:.3f}  coste={total_cost:.2f} USD/h")

    save_bus_results(run_id, bus_rows)
    save_gen_results(run_id, gen_rows)
    save_line_results(run_id, line_rows)
    save_kpis(run_id, kpi_rows)
    finish_run(run_id, status="ok")

    print(f"\nRun {run_id} finalizado. Filas: "
          f"{len(bus_rows)} buses, {len(gen_rows)} gens, "
          f"{len(line_rows)} líneas, {len(kpi_rows)} KPIs.")


if __name__ == "__main__":
    main()