from datetime import datetime, timezone, timedelta

from db.load_network import load_network
from db.save_results import (
    create_run, save_bus_results, save_gen_results,
    save_line_results, save_kpis, finish_run,
)
from solver.dc_opf import solve_dc_opf
from scenarios.apply import load_scenario_network
from scenarios.n1_batch import create_contingency_scenario, list_all_lines_and_gens
from ingest.synthetic_profile import daily_demand_profile


RUN_DATE = datetime(2024, 1, 15, 0, 0, tzinfo=timezone.utc)
HOURS    = 24


def run_one(scenario_id: int, net_base: dict, profile):
    net = load_scenario_network(scenario_id, net_base)

    run_id = create_run(
        scenario_id=scenario_id,
        t_start=RUN_DATE,
        t_end=RUN_DATE + timedelta(hours=HOURS),
        config={"profile": "daily_synthetic", "seed": 42, "hours": HOURS, "batch": "n1"},
    )

    bus_rows, gen_rows, line_rows, kpi_rows = [], [], [], []

    for h in range(HOURS):
        ts = RUN_DATE + timedelta(hours=h)
        factor = float(profile[h])

        try:
            result = solve_dc_opf(net, demand_factor=factor)
        except RuntimeError as e:
            # Escenario infactible: marcamos y salimos
            finish_run(run_id, status="failed")
            return run_id, f"FAILED: {e}"

        for bid, th, lmp in zip(result["bus_ids"], result["theta"], result["lmp"]):
            bus_rows.append((ts, bid, th, lmp))
        for gid, p in zip(result["gen_ids"], result["p"]):
            gen_rows.append((ts, gid, p))
        for line in net["lines"]:
            lid = line["id"]
            flow = result["flows"][lid]
            s_max = float(line["s_max_mva"])
            loading = abs(flow) / s_max * 100.0
            line_rows.append((ts, lid, flow, loading))

        kpi_rows.append((
            ts,
            result["cost"],
            float(max(result["lmp"])),
            float(min(result["lmp"])),
            sum(1 for r in line_rows if r[0] == ts and r[3] > 90),
            0.0,
        ))

    save_bus_results(run_id, bus_rows)
    save_gen_results(run_id, gen_rows)
    save_line_results(run_id, line_rows)
    save_kpis(run_id, kpi_rows)
    finish_run(run_id, status="ok")

    return run_id, "OK"


def main():
    net_base = load_network()
    profile = daily_demand_profile(hours=HOURS, seed=42)

    items = list_all_lines_and_gens()
    print(f"Total contingencias a procesar: {len(items)}")

    for kind, target_id, name in items:
        scenario_id = create_contingency_scenario(kind, target_id, name)
        run_id, status = run_one(scenario_id, net_base, profile)
        print(f"  {kind:4s} {target_id:3d}  scenario={scenario_id}  run={run_id}  {status}")


if __name__ == "__main__":
    main()