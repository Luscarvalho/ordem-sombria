extends RefCounted
## Wave pacing, distinct enemy behaviours and announced five-minute bosses.
const Data = preload("res://scripts/game_data.gd")
const Waves = preload("res://scripts/encounter_data.gd")
var game: Node2D
var phase := -1
var announcement := ""
var announcement_hint := ""
var announcement_time := 0.0
var warned_boss := 0
var boss_number := 0
var respite := 0.0
var hostile_bullets: Array[Dictionary] = []
var summons: Array[Dictionary] = []
var neighbors: Dictionary = {}
var spawn_sectors: Array[int] = []

func _init(host: Node2D) -> void:
	game = host

func reset() -> void:
	game.boss_arena.release()
	phase = -1
	announcement = ""
	announcement_time = 0.0
	warned_boss = 0
	boss_number = 0
	respite = 0.0
	hostile_bullets.clear()
	summons.clear()
	neighbors.clear()
	spawn_sectors.clear()

func announce(title: String, hint: String, duration: float = 3.0) -> void:
	announcement = title
	announcement_hint = hint
	announcement_time = duration

func update(delta: float) -> void:
	announcement_time = maxf(0.0, announcement_time - delta)
	respite = maxf(0.0, respite - delta)
	var next_phase := Waves.phase_index(game.elapsed)
	if next_phase != phase:
		phase = next_phase
		announce(Waves.PHASES[phase].name, Waves.PHASES[phase].hint)
	var due := floori(game.boss_clock / Waves.BOSS_INTERVAL)
	if game.elapsed >= game.boss_clock - 5.0 and warned_boss < due:
		warned_boss = due
		game.attract_all_experience()
		game.spawn_clock = maxf(game.spawn_clock, 5.0)
		announce("UMA PRESENÇA SE APROXIMA", "Almas atraídas. O chefe chega em 5 segundos.", 5.0)
	if game.elapsed >= game.boss_clock:
		boss_number = due
		spawn_boss(boss_number)
		game.boss_clock += Waves.BOSS_INTERVAL
	game.spawn_clock -= delta
	if game.spawn_clock <= 0:
		_spawn_wave(Waves.PHASES[phase])
	_index_neighbors()

func _spawn_wave(spec: Dictionary) -> void:
	var pressure := 0
	var common := 0
	for enemy in game.enemies:
		if enemy.hp > 0 and not enemy.brain.get("boss", false):
			common += 1
			if enemy.position.distance_squared_to(game.player.position) < Waves.PRESSURE_RADIUS * Waves.PRESSURE_RADIUS:
				pressure += 1
	if pressure >= Waves.PRESSURE_LIMIT:
		game.spawn_clock = Waves.PRESSURE_RETRY
		return
	var pack: int = spec.pack
	var interval: float = spec.interval
	var cap: int = spec.cap
	if current_boss() != null:
		pack = 1
		interval *= 2.2
		cap = mini(cap, Waves.BOSS_HORDE_CAP)
	if respite > 0.0:
		pack = 1
		interval *= 2.5
	for member in range(pack):
		if common >= cap or game.enemies.size() >= Waves.MAX_ENEMIES:
			break
		game._spawn_enemy(choose_type())
		common += 1
	var phase_age: float = game.elapsed - float(spec.at)
	game.spawn_clock = interval * lerpf(1.0, 0.80, minf(1.0, phase_age / 60.0))

func spawn_position(radius: float) -> Vector2:
	if spawn_sectors.is_empty():
		for sector in range(Waves.SPAWN_SECTORS):
			spawn_sectors.append(sector)
		for index in range(spawn_sectors.size() - 1, 0, -1):
			var other: int = game.rng.randi_range(0, index)
			var previous := spawn_sectors[index]
			spawn_sectors[index] = spawn_sectors[other]
			spawn_sectors[other] = previous
	var sector: int = spawn_sectors.pop_back()
	var angle: float = (sector + 0.5 + game.rng.randf_range(-0.22, 0.22)) * TAU / Waves.SPAWN_SECTORS
	var direction := Vector2.from_angle(angle)
	var half: Vector2 = game.get_viewport_rect().size / game.camera.zoom * 0.5
	var edge := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	return game.player.position + direction * (edge + Waves.SPAWN_MARGIN + radius)

func _index_neighbors() -> void:
	neighbors.clear()
	for enemy in game.enemies:
		if enemy.hp <= 0:
			continue
		var cell := Vector2i(floori(enemy.position.x / Waves.NEIGHBOR_CELL), floori(enemy.position.y / Waves.NEIGHBOR_CELL))
		if not neighbors.has(cell):
			neighbors[cell] = []
		neighbors[cell].append(enemy)

func choose_type() -> int:
	var spec: Dictionary = Waves.PHASES[Waves.phase_index(game.elapsed)]
	var total := 0
	for weight in spec.weights.values():
		total += int(weight)
	var roll: int = game.rng.randi_range(1, total)
	var selected := 0
	for id in spec.weights:
		roll -= int(spec.weights[id])
		if roll <= 0:
			selected = id
			break
	if selected in [1, 6]:
		var ranged := 0
		for enemy in game.enemies:
			if enemy.hp > 0 and enemy.enemy_type in [1, 6]:
				ranged += 1
		var cap := mini(8, 2 + floori(maxf(0, game.elapsed - 120) / 120))
		if ranged >= cap:
			return 0
	return selected

func setup(enemy: Node2D, type: int) -> void:
	var stats: Dictionary = Data.ENEMIES[type]
	enemy.enemy_type = type
	enemy.brain = {"role": stats.role, "clock": game.rng.randf_range(1.4, 2.6), "windup": 0.0, "charge": 0.0, "target": Vector2.ZERO, "direction": Vector2.RIGHT, "boss": stats.role == "boss", "enraged": false}
	if stats.role == "boss":
		enemy.brain.archetype = "colossus"
		enemy.brain.title = "COLOSSO DAS CINZAS"

func spawn_boss(number: int) -> Node2D:
	game.attract_all_experience()
	game.boss_arena.begin(game.player.position)
	var scene: PackedScene = game.MatriarchScene if number % 2 == 0 else game.EnemyScenes[3]
	var template: CharacterBody2D = scene.instantiate()
	var base_health: float = template.max_hp
	var base_damage: float = template.damage
	var base_speed: float = template.speed
	var base_xp: int = template.xp
	var distance: float = game.BossArena.RADIUS-template.radius-24.0
	var point: Vector2 = game.boss_arena.position+Vector2.from_angle(game.rng.randf()*TAU)*distance
	point = game.boss_arena.fit_position(point,template.radius,game.obstacles)
	template.free()
	var boss: CharacterBody2D = game._spawn_enemy(0 if number % 2 == 0 else 3, point, scene)
	boss.max_hp = base_health * (1.0 + 0.65 * (number - 1))
	boss.hp = boss.max_hp
	boss.damage = base_damage + 3.0 * (number - 1)
	boss.xp = base_xp + 25 * (number - 1)
	if number % 2 == 0:
		boss.brain.role = "boss"
		boss.brain.boss = true
		boss.brain.archetype = "matriarch"
		boss.brain.title = "MATRIARCA DO ENXAME"
		boss.speed = base_speed
	game._sync_camera(true)
	boss.reset_physics_interpolation()
	announce(boss.brain.title, "CHEFE %d / Ataques marcados no chão. Prepare sua esquiva." % number, 3.5)
	return boss

func current_boss() -> Node2D:
	for enemy in game.enemies:
		if enemy.hp > 0.0 and enemy.brain.get("boss", false):
			return enemy
	return null

func movement(enemy: Node2D, delta: float) -> Vector2:
	var b: Dictionary = enemy.brain
	var direction: Vector2 = enemy.position.direction_to(game.player.position)
	var distance: float = enemy.position.distance_to(game.player.position)
	var role: String = b.role
	var desired: Vector2 = direction * enemy.speed
	if role in ["shooter", "spitter"]:
		desired = _ranged_movement(enemy, direction, distance, delta)
	elif role in ["charger", "boss"]:
		desired = _charge_or_boss(enemy, direction, distance, delta)
	if b.windup <= 0.0 and b.charge <= 0.0 and desired.length_squared() > 0.0 and desired.length() <= enemy.speed * 1.5:
		desired = (desired + _separation(enemy) * enemy.speed * Waves.SEPARATION_STRENGTH).limit_length(enemy.speed * 1.08)
		desired = game.obstacles.steer(enemy, desired)
	return desired

func _separation(enemy: Node2D) -> Vector2:
	var cell := Vector2i(floori(enemy.position.x / Waves.NEIGHBOR_CELL), floori(enemy.position.y / Waves.NEIGHBOR_CELL))
	var result := Vector2.ZERO
	for x in range(-1,2):
		for y in range(-1,2):
			for other in neighbors.get(cell+Vector2i(x,y), []):
				if other == enemy or not is_instance_valid(other) or other.hp <= 0:
					continue
				var offset: Vector2 = enemy.position-other.position
				var distance := offset.length()
				var minimum: float = enemy.radius+other.radius+Waves.SEPARATION_GAP
				if distance < minimum:
					var away := offset / distance if distance > 0.01 else Vector2.from_angle(fposmod(enemy.get_instance_id()*0.73,TAU))
					result += away * (1.0-distance/minimum)
	return result.limit_length(2.0)

func _visible(enemy: Node2D) -> bool:
	var half: Vector2 = game.get_viewport_rect().size / game.camera.zoom * 0.5 - Vector2(30, 36)
	var point: Vector2 = enemy.position - game.camera.position
	return absf(point.x) < half.x and absf(point.y - 20.0) < half.y

func _ranged_movement(enemy: Node2D, direction: Vector2, distance: float, delta: float) -> Vector2:
	var b: Dictionary = enemy.brain
	if b.windup > 0.0:
		b.windup = maxf(0, b.windup - delta)
		if b.windup == 0.0:
			shoot_fan(enemy, b.target, 3 if b.role == "spitter" else 1, 0.20, 120.0 if b.role == "spitter" else 135.0, enemy.damage)
			b.clock = 3.2 if b.role == "spitter" else 2.6
		return Vector2.ZERO
	b.clock -= delta
	if not game.obstacles.clear_shot(enemy.position + Vector2(0,-20), game.player.position + Vector2(0,-15)):
		return direction * enemy.speed
	if b.clock <= 0 and distance < 310.0 and _visible(enemy):
		b.windup = 0.65 if b.role == "spitter" else 0.55
		b.target = game.player.position + Vector2(0, -15)
		return Vector2.ZERO
	if distance > 215.0:
		return direction * enemy.speed
	if distance < 125.0:
		return -direction * enemy.speed * 0.65
	# Strafe slowly while retaining shooting distance; avoid static turret behaviour.
	return direction.orthogonal() * sin(game.elapsed * 0.8 + enemy.phase) * enemy.speed * 0.28

func _charge_or_boss(enemy: Node2D, direction: Vector2, distance: float, delta: float) -> Vector2:
	var b: Dictionary = enemy.brain
	var boss: bool = b.boss
	if boss and not b.enraged and enemy.hp <= enemy.max_hp * 0.5:
		b.enraged = true
		announce(b.title, "O chefe ficou furioso! Os ataques serão mais frequentes.", 2.5)
	if b.charge > 0.0:
		b.charge = maxf(0, b.charge - delta)
		if b.charge == 0.0:
			if boss:
				shoot_ring(enemy, 10 if b.enraged else 8, 105.0, 12.0)
			b.clock = (4.0 if b.enraged else 5.5) if boss else 3.5
		return Vector2(b.direction) * (285.0 if boss else 205.0)
	if b.windup > 0.0:
		b.windup = maxf(0, b.windup - delta)
		if b.windup == 0.0:
			if b.get("archetype", "") == "matriarch":
				shoot_fan(enemy, b.target, 7 if b.enraged else 5, 0.24, 110.0, 12.0)
				var count := 6 if b.enraged else 4
				for i in range(count):
					summons.append({"position": enemy.position + Vector2.from_angle(i * TAU / count) * 65, "type": 4})
				b.clock = 4.5 if b.enraged else 6.5
			else:
				b.charge = 0.70 if boss else 0.45
				b.direction = enemy.position.direction_to(b.target - Vector2(0, -15))
		return Vector2.ZERO
	b.clock -= delta
	if b.clock <= 0.0 and distance < (370.0 if boss else 220.0) and _visible(enemy):
		b.windup = 0.9 if boss else 0.55
		b.target = game.player.position + Vector2(0, -15)
		return Vector2.ZERO
	return direction * enemy.speed

func flush_summons() -> void:
	for pending in summons:
		if game.enemies.size() >= Waves.MAX_ENEMIES:
			break
		var point: Vector2 = pending.position
		if point.distance_to(game.player.position) < 95.0:
			point = game.player.position + game.player.position.direction_to(point) * 110
		game._spawn_enemy(pending.type, point)
	summons.clear()

func shoot_fan(enemy: Node2D, target: Vector2, count: int, spread: float, speed: float, damage: float) -> void:
	var origin: Vector2 = enemy.position + Vector2(0, -20)
	var direction := origin.direction_to(target)
	for i in range(count):
		_add_bullet(origin, direction.rotated((i-(count-1)*0.5)*spread)*speed, damage, enemy.enemy_type == 6)

func shoot_ring(enemy: Node2D, count: int, speed: float, damage: float) -> void:
	for i in range(count):
		_add_bullet(enemy.position + Vector2(0,-20), Vector2.from_angle(i * TAU / count + game.elapsed * 0.1)*speed, damage, false)

func _add_bullet(origin: Vector2, velocity: Vector2, damage: float, venom: bool) -> void:
	if hostile_bullets.size() >= Waves.MAX_PROJECTILES:
		return
	hostile_bullets.append({"position": origin, "previous": origin, "velocity": velocity, "damage": damage, "life": 5.5, "venom": venom})

func update_projectiles(delta: float) -> void:
	for i in range(hostile_bullets.size()-1,-1,-1):
		var bullet: Dictionary = hostile_bullets[i]
		var old: Vector2 = bullet.position
		bullet.previous = old
		bullet.position += bullet.velocity * delta
		var terrain_fraction: float = game.obstacles.projectile_fraction(old, bullet.position)
		var blocked := terrain_fraction < 1.0
		if blocked:
			bullet.position = old.lerp(bullet.position, terrain_fraction)
		bullet.life -= delta
		if game.player.intersects_projectile(old, bullet.position):
			game._damage_player(bullet.damage)
			hostile_bullets.remove_at(i)
			if game.state == "dead":
				return
		elif blocked or bullet.life <= 0.0 or bullet.position.distance_squared_to(game.player.position) > 1500.0*1500.0:
			hostile_bullets.remove_at(i)

func on_death(enemy: Node2D) -> void:
	if enemy.brain.get("boss", false):
		if current_boss() == null:
			game.boss_arena.release()
			game._sync_camera(true)
		hostile_bullets.clear()
		respite = 8.0
		game.buffs.heal(20.0)
		announce("CHEFE DERROTADO", "+20 de vida / Uma breve folga antes da próxima horda.", 3.5)

func draw(canvas: Node2D, fraction: float) -> void:
	for enemy in game.enemies:
		if enemy.hp <= 0 or enemy.brain.get("windup", 0.0) <= 0.0:
			continue
		var b: Dictionary = enemy.brain
		var from: Vector2 = enemy.position + Vector2(0,-15)
		var to: Vector2 = b.target
		var color := Color(1.0,0.51,0.43,0.65) if b.role in ["boss","charger"] else Color(0.91,0.40,0.57,0.55)
		var direction := from.direction_to(to)
		for step in range(0, int(from.distance_to(to)), 18):
			canvas.draw_line(from+direction*step, from+direction*(step+8),color,2.0)
		canvas.draw_arc(to, 12, 0, TAU, 8, color, 2.0)
	for bullet in hostile_bullets:
		var p: Vector2 = Vector2(bullet.previous).lerp(bullet.position, fraction).round()
		canvas.draw_circle(p, 6, Color("2c142a"))
		canvas.draw_circle(p, 4, Color("ef738e"))
		canvas.draw_rect(Rect2(p-Vector2(2,2), Vector2(4,4)), Color("add77e") if bullet.venom else Color("ffe0c0"))
