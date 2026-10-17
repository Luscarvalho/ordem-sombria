extends RefCounted
## A slow introduction of behaviours, followed by bosses every five run minutes.
const BOSS_INTERVAL := 300.0
const MAX_ENEMIES := 180
const MAX_PROJECTILES := 120
const SPAWN_SECTORS := 8
const SPAWN_MARGIN := 72.0
const NEIGHBOR_CELL := 96.0
const SEPARATION_GAP := 12.0
const SEPARATION_STRENGTH := 1.6
const PRESSURE_RADIUS := 240.0
const PRESSURE_LIMIT := 18
const PRESSURE_RETRY := 0.8
const BOSS_HORDE_CAP := 24
const PHASES := [
	{"at": 0.0, "name": "ARANHAS", "hint": "A toca desperta. Mantenha distância.", "interval": 1.0, "pack": 1, "cap": 20, "weights": {0: 100}},
	{"at": 30.0, "name": "ENXAME", "hint": "Mais aranhas estão saindo da toca.", "interval": 1.25, "pack": 2, "cap": 30, "weights": {0: 100}},
	{"at": 60.0, "name": "PERSEGUIÇÃO", "hint": "Aranhas velozes se juntam ao enxame.", "interval": 1.2, "pack": 2, "cap": 40, "weights": {0: 82, 4: 18}},
	{"at": 105.0, "name": "CARAPAÇAS", "hint": "As aranhas maiores resistem a mais tiros.", "interval": 1.3, "pack": 2, "cap": 48, "weights": {0: 72, 4: 20, 5: 8}},
	{"at": 120.0, "name": "OLHOS VIGIAS", "hint": "Olhos miram de longe. Desvie das esferas vermelhas.", "interval": 1.3, "pack": 3, "cap": 54, "weights": {0: 64, 4: 20, 5: 8, 1: 8}},
	{"at": 180.0, "name": "A CAÇADA", "hint": "As feras preparam uma arrancada antes de atacar.", "interval": 1.2, "pack": 3, "cap": 64, "weights": {0: 53, 4: 20, 5: 9, 1: 8, 2: 10}},
	{"at": 240.0, "name": "VENENO", "hint": "Cuspidores atacam em leque. Procure as aberturas.", "interval": 1.25, "pack": 3, "cap": 72, "weights": {0: 47, 4: 18, 5: 10, 1: 10, 2: 9, 6: 6}},
	{"at": 300.0, "name": "NOITE PROFUNDA", "hint": "A horda combina todos os ataques que você conhece.", "interval": 1.2, "pack": 3, "cap": 84, "weights": {0: 42, 4: 18, 5: 12, 1: 10, 2: 10, 6: 8}},
]

static func phase_index(time: float) -> int:
	var result := 0
	for i in range(PHASES.size()):
		if time >= PHASES[i].at:
			result = i
	return result
