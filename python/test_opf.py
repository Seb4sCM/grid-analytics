from db.load_network import load_network
from solver.dc_opf import solve_dc_opf

net = load_network()
r = solve_dc_opf(net, demand_factor=1.0)

print(f"Coste total: {r['cost']:.2f} USD/h")
print()
print("Despacho por generador (MW):")
for gid, p in zip(r["gen_ids"], r["p"]):
    print(f"  Gen {gid}: {p:+8.2f}")
print(f"  Total: {sum(r['p']):.2f} MW")
print()
print("Demanda total:", sum(l["p_nom_mw"] for l in net["loads"]), "MW")
print()
print("Ángulos (rad):")
for bid, th in zip(r["bus_ids"], r["theta"]):
    print(f"  Bus {bid:2d}: {th:+8.5f}")
print()
print("LMP (USD/MWh):")
for bid, m in zip(r["bus_ids"], r["lmp"]):
    print(f"  Bus {bid:2d}: {m:+8.3f}")