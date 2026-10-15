from db.load_network import load_network

net = load_network()
print("buses:     ", len(net["buses"]))
print("generators:", len(net["generators"]))
print("lines:     ", len(net["lines"]))
print("loads:     ", len(net["loads"]))
print()
print("Primer bus:", net["buses"][0])
print("Primera línea:", net["lines"][0])