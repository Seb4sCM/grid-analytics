from db.load_network import load_network
from solver.dc_pf import solve_dc_pf

net = load_network()
result = solve_dc_pf(net)

print("Ángulos (rad):")
for bid, th in zip(result["bus_ids"], result["theta"]):
    print(f"  Bus {bid:2d}: {th:+.5f}")

print()
print("Flujos por línea (MW):")
for lid, f in result["flows"].items():
    print(f"  Línea {lid:2d}: {f:+8.2f}")

# Verificación de balance
total_gen = sum(g["p_max_mw"] for g in net["generators"])
total_dem = sum(l["p_nom_mw"] for l in net["loads"])
print()
print(f"Generación total: {total_gen:.2f} MW")
print(f"Demanda total:    {total_dem:.2f} MW")
print(f"Diferencia:       {total_gen - total_dem:+.2f} MW (debería ser 0)")


