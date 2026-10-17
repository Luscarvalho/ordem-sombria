extends RefCounted
## Balance and descriptions live here so new weapons/upgrades need no UI changes.

# Leave more combat time between upgrade choices, especially early in a run.
const FIRST_LEVEL_XP := 40
const LEVEL_XP_GROWTH := 1.35
const LEVEL_XP_FLAT := 10

const WEAPONS := {
	"revolver": {"title": "REVÓLVER", "tag": "PRECISÃO", "description": "Tiros fortes e certeiros.\nAlcance médio-longo.", "range": 300.0, "range_label": "MÉDIO-LONGO", "damage": 24.0, "interval": 0.48, "ammo": 6, "reload_time": 1.2, "pellets": 1, "pierce": 0, "spread": 0.0, "speed": 660.0, "color": Color("f4bd72")},
	"shotgun": {"title": "ESCOPETA", "tag": "CURTA DISTÂNCIA", "description": "Cinco projéteis em leque.\nMuito forte de perto.", "range": 160.0, "range_label": "CURTO", "damage": 12.0, "interval": 0.95, "ammo": 2, "reload_time": 1.6, "pellets": 5, "pierce": 0, "spread": 0.15, "speed": 510.0, "color": Color("ef916e")},
	"wand": {"title": "CAJADO", "tag": "MAGIA", "description": "Magia de alcance médio.\nAtravessa dois inimigos.", "range": 240.0, "range_label": "MÉDIO", "damage": 15.0, "interval": 0.34, "ammo": 8, "reload_time": 1.8, "pellets": 1, "pierce": 1, "spread": 0.0, "speed": 470.0, "color": Color("81d8c6")},
}

static func weapon_stats(id: String) -> Array[Dictionary]:
	var weapon: Dictionary = WEAPONS[id]
	return [
		{"label": "DANO / PROJÉTIL", "value": str(roundi(weapon.damage))},
		{"label": "DISPAROS / SEG", "value": ("%.2f" % (1.0 / weapon.interval)).replace(".", ",")},
		{"label": "ALCANCE", "value": "%d u" % weapon.range},
		{"label": "CARGAS" if id == "wand" else "CARREGADOR", "value": str(weapon.ammo)},
		{"label": "RECARGA", "value": ("%.1f s" % weapon.reload_time).replace(".", ",")},
		{"label": "PROJÉTEIS", "value": str(weapon.pellets)},
		{"label": "PERFURAÇÃO", "value": "+%d %s" % [weapon.pierce, "alvo" if weapon.pierce == 1 else "alvos"]},
	]

const UPGRADES := [
	{"id": "reload", "title": "Recarga ágil", "tag": "RECARGA", "max_level": 3, "color": Color("e8c181")},
	{"id": "ammo", "title": "Bandoleira", "tag": "MUNIÇÃO", "max_level": 3, "color": Color("b2c9e8")},
	{"id": "damage", "title": "Pólvora sombria", "tag": "DANO", "max_level": 5, "color": Color("efb775")},
	{"id": "attack", "title": "Mãos ligeiras", "tag": "CADÊNCIA", "max_level": 5, "color": Color("e8c181")},
	{"id": "speed", "title": "Passo fantasma", "tag": "MOVIMENTO", "max_level": 3, "color": Color("97cdbb")},
	{"id": "projectile", "title": "Disparo duplo", "tag": "PROJÉTEIS", "max_level": 3, "color": Color("efb775")},
	{"id": "pierce", "title": "Atravessar", "tag": "PERFURAÇÃO", "max_level": 3, "color": Color("b2c9e8")},
	{"id": "vitality", "title": "Sangue novo", "tag": "VITALIDADE", "max_level": 3, "color": Color("e68a9b")},
	{"id": "magnet", "title": "Colheita de almas", "tag": "COLETA", "max_level": 3, "color": Color("83c9b3")},
	{"id": "ember", "title": "Brasa viva", "tag": "FOGO", "max_level": 3, "color": Color("f09b68")},
	{"id": "critical", "title": "Ponto fraco", "tag": "CRÍTICO", "max_level": 3, "color": Color("efb775")},
	{"id": "ricochet", "title": "Ricochete", "tag": "PROJÉTEIS", "max_level": 3, "color": Color("b2c9e8")},
	{"id": "finisher", "title": "Último suspiro", "tag": "TIRO PODEROSO", "max_level": 3, "color": Color("f09b68")},
	{"id": "frost", "title": "Toque gelado", "tag": "GELO", "max_level": 3, "color": Color("8fd4ed")},
	{"id": "poison", "title": "Veneno sombrio", "tag": "VENENO", "max_level": 3, "color": Color("add77e")},
	{"id": "explosion", "title": "Cadáver explosivo", "tag": "EXPLOSÃO", "max_level": 3, "color": Color("f09b68")},
	{"id": "lightning", "title": "Corrente elétrica", "tag": "RAIO", "max_level": 3, "color": Color("c8b6f0")},
	{"id": "orbs", "title": "Orbes protetores", "tag": "ORBITAIS", "max_level": 3, "color": Color("bfa0e6")},
	{"id": "shield", "title": "Barreira sombria", "tag": "ESCUDO", "max_level": 3, "color": Color("8fd4ed")},
	{"id": "vampire", "title": "Sede de sangue", "tag": "CURA", "max_level": 3, "color": Color("e68a9b")},
	{"id": "revenge", "title": "Vingança", "tag": "CONTRA-ATAQUE", "max_level": 3, "color": Color("df9fcb")},
	{"id": "pact", "title": "Pacto sombrio", "tag": "RISCO / PODER", "max_level": 3, "color": Color("d68dba")},
]

static func upgrade(id: String) -> Dictionary:
	for item in UPGRADES:
		if item.id == id:
			return item
	return {}

static func upgrade_preview(id: String, current: int, context: Dictionary = {}) -> String:
	var a := current
	var b := mini(current + 1, int(upgrade(id).max_level))
	match id:
		"reload":
			var base: float = WEAPONS[context.get("weapon", "revolver")].reload_time
			return ("RECARGA: %.2f s > %.2f s\nVELOCIDADE: +%d%% > +%d%%" % [base/(1.0+0.2*a),base/(1.0+0.2*b),a*20,b*20]).replace(".", ",")
		"ammo":
			var base: int = WEAPONS[context.get("weapon", "revolver")].ammo
			return "CAPACIDADE: %d > %d\n+2 MUNIÇÕES POR NÍVEL." % [base+2*a,base+2*b]
		"damage": return "Dano da arma\n+%d%% > +%d%%" % [25 * a, 25 * b]
		"attack": return "Velocidade de disparo\n+%d%% > +%d%%" % [roundi((pow(1.15, a) - 1) * 100), roundi((pow(1.15, b) - 1) * 100)]
		"speed": return "Velocidade ao andar\n+%d%% > +%d%%" % [roundi((pow(1.12, a) - 1) * 100), roundi((pow(1.12, b) - 1) * 100)]
		"projectile": return "Projéteis adicionais\n+%d > +%d por disparo" % [a, b]
		"pierce": return "Alvos extras por tiro\n+%d > +%d" % [a, b]
		"vitality": return "Vida máxima: +%d > +%d\nRecupera 30 de vida.\nPacto reduz o bônus." % [20 * a, 20 * b]
		"magnet": return "Raio de coleta de almas\n+%d%% > +%d%%" % [roundi((pow(1.45, a) - 1) * 100), roundi((pow(1.45, b) - 1) * 100)]
		"ember": return "Queimadura por 3 s\n%d > %d de dano/s" % [9 * a, 9 * b]
		"critical": return "Chance de dano dobrado\n%d%% > %d%%" % [15 * a, 15 * b]
		"ricochet": return "Rebate em outros alvos\n%d > %d salto(s)\nCada salto: 50%% do dano." % [a, b]
		"finisher": return "Disparo com dano triplo\nA cada %s > %d tiros" % [str(10 - 2 * a) if a > 0 else "--", 10 - 2 * b]
		"frost": return "Lentidão por 2 s\n%d%% > %d%% mais lento" % [20 + 10 * a if a > 0 else 0, 20 + 10 * b]
		"poison": return "Envenena durante 4 s\n%d > %d de dano/s" % [6 * a, 6 * b]
		"explosion": return "Chance ao matar\n%d%% > %d%%\nExplosão: %d de dano." % [10 + 10 * a if a > 0 else 0, 10 + 10 * b, 15 + 20 * b]
		"lightning": return "Raio a cada 5 disparos\n%d > %d alvos\nDano: %d > %d" % [2 + a if a > 0 else 0, 2 + b, 12 + 8 * a if a > 0 else 0, 12 + 8 * b]
		"orbs": return "Esferas ao seu redor\n%d > %d orbes\nDano: %d > %d" % [a + 1 if a > 0 else 0, b + 1, 8 + 6 * a if a > 0 else 0, 8 + 6 * b]
		"shield": return "Bloqueia um golpe\nRecarga: %s > %d s" % [str(24 - 4 * a) if a > 0 else "--", 24 - 4 * b]
		"vampire": return "A cada 10 abates\nRecupera %d > %d de vida" % [2 * a, 2 * b]
		"revenge": return "Ao sofrer dano, empurra\ninimigos ao redor.\nDano da onda: %d > %d" % [15 * a, 15 * b]
		"pact":
			var stacks: Dictionary = context.get("stacks", {})
			var base_health := 100.0 + 20.0 * int(stacks.get("vitality", 0))
			var base_damage: float = WEAPONS[context.get("weapon", "revolver")].damage
			var power := 1.0 + 0.25 * int(stacks.get("damage", 0))
			return "Troque vida por dano.\nDano/proj.: %d > %d\nVida máx.: %d > %d\nVale por toda a caçada." % [roundi(base_damage * (power + 0.4 * a)), roundi(base_damage * (power + 0.4 * b)), ceili(base_health * pow(0.75, a)), ceili(base_health * pow(0.75, b))]
	return ""

# Regions reference the approved preview without resampling or altering its pixels.
const REGIONS := [Rect2(20, 380, 300, 370), Rect2(380, 525, 310, 235), Rect2(710, 335, 290, 415), Rect2(1035, 320, 400, 440), Rect2(1440, 115, 540, 645)]
const HEIGHTS := [60.0, 33.0, 52.0, 66.0, 96.0, 48.0]
const ENEMIES := [
	{"name": "Aranha", "art": 1, "role": "melee", "hp": 30.0, "speed": 56.0, "damage": 10.0, "xp": 2, "radius": 13.0},
	{"name": "Olho vigia", "art": 2, "role": "shooter", "hp": 48.0, "speed": 54.0, "damage": 12.0, "xp": 5, "radius": 17.0},
	{"name": "Fera", "art": 3, "role": "charger", "hp": 90.0, "speed": 78.0, "damage": 16.0, "xp": 7, "radius": 18.0},
	{"name": "Colosso das cinzas", "art": 4, "role": "boss", "hp": 1600.0, "speed": 38.0, "damage": 24.0, "xp": 100, "radius": 32.0},
	{"name": "Aranha veloz", "art": 1, "role": "runner", "hp": 20.0, "speed": 88.0, "damage": 8.0, "xp": 2, "radius": 11.0},
	{"name": "Aranha de carapaça", "art": 1, "role": "armored", "hp": 105.0, "speed": 41.0, "damage": 15.0, "xp": 5, "radius": 17.0},
	{"name": "Cuspidor de veneno", "art": 5, "role": "spitter", "hp": 82.0, "speed": 45.0, "damage": 12.0, "xp": 7, "radius": 17.0},
]
