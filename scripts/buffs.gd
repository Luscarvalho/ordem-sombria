extends RefCounted
## Combat effects for ranked cards. All clocks advance only with the run.

var game: Node2D
var shots := 0
var shield_ready := false
var shield_clock := 0.0
var orb_hits: Dictionary = {}
var orbs: Array[Dictionary] = []
var visuals: Array[Dictionary] = []

func _init(host: Node2D) -> void:
	game = host

func rank(id: String) -> int:
	return int(game.stacks.get(id, 0))

func reset() -> void:
	shots = 0
	shield_ready = false
	shield_clock = 0.0
	orb_hits.clear()
	orbs.clear()
	visuals.clear()

func refresh_stats() -> void:
	game.damage_multiplier = 1.0 + rank("damage") * 0.25 + rank("pact") * 0.40
	game.rate_multiplier = pow(1.15, rank("attack"))
	game.weapon_cycle.set_modifiers(2*rank("ammo"), 1.0+0.20*rank("reload"))
	game.move_speed = 170.0 * pow(1.12, rank("speed"))
	game.pickup_radius = 65.0 * pow(1.45, rank("magnet"))
	game.extra_pellets = rank("projectile")
	game.extra_pierce = rank("pierce")
	game.fire_damage = rank("ember") * 9.0
	game.max_health = (100.0 + rank("vitality") * 20.0) * pow(0.75, rank("pact"))
	game.health = minf(game.health, game.max_health)
	if rank("shield") > 0:
		shield_clock = minf(shield_clock, 24.0 - 4.0 * rank("shield"))

func update(delta: float) -> void:
	for i in range(visuals.size() - 1, -1, -1):
		visuals[i].life -= delta
		if visuals[i].life <= 0.0:
			visuals.remove_at(i)
	if rank("shield") > 0 and not shield_ready:
		shield_clock = maxf(0.0, shield_clock - delta)
		if shield_clock == 0.0:
			shield_ready = true
	var count := rank("orbs") + 1 if rank("orbs") > 0 else 0
	while orbs.size() < count:
		orbs.append({"position": game.player.position, "previous": game.player.position})
	for i in range(count):
		var orb: Dictionary = orbs[i]
		orb.previous = orb.position
		orb.position = game.player.position + Vector2(0, -15) + Vector2.from_angle(game.elapsed * 2.4 + i * TAU / count) * 56
		for enemy in game.enemies:
			if enemy.hp <= 0 or game.elapsed < orb_hits.get(enemy.get_instance_id(), 0.0):
				continue
			if orb.position.distance_to(enemy.position + Vector2(0, -14)) < enemy.radius + 7:
				damage(enemy, 8.0 + 6.0 * rank("orbs"), Color("bfa0e6"))
				orb_hits[enemy.get_instance_id()] = game.elapsed + 0.55

func on_shot(target: Node2D, muzzle: Vector2) -> float:
	shots += 1
	if rank("lightning") > 0 and shots % 5 == 0:
		_chain_lightning(target, muzzle)
	if rank("finisher") > 0 and shots % (10 - 2 * rank("finisher")) == 0:
		pulse(muzzle, 15, Color("efb775"))
		return 3.0
	return 1.0

func hit_projectile(enemy: Node2D, bullet: Dictionary) -> void:
	var amount: float = bullet.damage
	var critical: bool = rank("critical") > 0 and game.rng.randf() < 0.15 * rank("critical")
	if critical:
		amount *= 2.0
	damage(enemy, amount, Color("efb775") if critical else bullet.color, critical)
	if game.fire_damage > 0.0:
		enemy.burn = 3.0
		enemy.burn_damage = game.fire_damage
	if rank("frost") > 0:
		enemy.slow_time = 2.0
		enemy.slow_factor = 1.0 - (0.20 + 0.10 * rank("frost"))
	if rank("poison") > 0:
		enemy.poison_time = 4.0
		enemy.poison_damage = 6.0 * rank("poison")

func damage(enemy: Node2D, amount: float, color: Color, critical: bool = false) -> void:
	if enemy.hp <= 0.0:
		return
	enemy.hp -= amount
	game.music.play_sfx("enemy_hit")
	enemy.flash = 0.08
	game._effect(enemy.position + Vector2(0, -34), "%d%s" % [roundi(amount), "!" if critical else ""], color)

func ricochet(bullet: Dictionary) -> bool:
	if bullet.get("bounces", 0) <= 0 or bullet.remaining <= 0.0:
		return false
	var best: Node2D = null
	var distance := 140.0 * 140.0
	for enemy in game.enemies:
		if enemy.hp <= 0.0 or enemy.get_instance_id() in bullet.hits:
			continue
		var center: Vector2 = enemy.position + Vector2(0, -14)
		if center.distance_to(bullet.origin) > bullet.reach:
			continue
		var candidate: float = center.distance_squared_to(bullet.position)
		if candidate < distance:
			best = enemy
			distance = candidate
	if best == null:
		return false
	var direction: Vector2 = bullet.position.direction_to(best.position + Vector2(0, -14))
	bullet.velocity = direction * bullet.velocity.length()
	var offset: Vector2 = bullet.position - bullet.origin
	var projection := offset.dot(direction)
	var boundary := -projection + sqrt(maxf(0.0, projection * projection + bullet.reach * bullet.reach - offset.length_squared()))
	bullet.remaining = minf(bullet.remaining, boundary)
	bullet.damage *= 0.5
	bullet.bounces -= 1
	pulse(bullet.position, 9, Color("b2c9e8"))
	return true

func on_kill(enemy: Node2D) -> void:
	orb_hits.erase(enemy.get_instance_id())
	if rank("vampire") > 0 and game.kills % 10 == 0:
		heal(2 * rank("vampire"))
	if rank("explosion") > 0 and game.rng.randf() < 0.10 + 0.10 * rank("explosion"):
		_area(enemy.position, 70.0, 15.0 + 20.0 * rank("explosion"), Color("f09b68"))

func block_hit() -> bool:
	if not shield_ready or rank("shield") == 0:
		return false
	shield_ready = false
	shield_clock = 24.0 - 4.0 * rank("shield")
	game.music.play_sfx("shield_block")
	pulse(game.player.position + Vector2(0, -15), 38, Color("8fd4ed"))
	game._effect(game.player.position + Vector2(0, -45), "BLOQUEADO", Color("8fd4ed"))
	return true

func on_player_hurt() -> void:
	if rank("revenge") > 0:
		_area(game.player.position, 100.0, 15.0 * rank("revenge"), Color("df9fcb"), 200.0 + 60.0 * rank("revenge"))

func heal(amount: float) -> void:
	var before: float = game.health
	game.health = minf(game.max_health, game.health + amount)
	if game.health > before:
		game._effect(game.player.position + Vector2(0, -48), "+%d VIDA" % ceili(game.health - before), Color("83c9b3"))

func _area(center: Vector2, radius: float, amount: float, color: Color, push: float = 0.0) -> void:
	pulse(center + Vector2(0, -14), radius, color)
	for enemy in game.enemies:
		if enemy.hp > 0 and center.distance_to(enemy.position) <= radius:
			damage(enemy, amount, color)
			if push > 0:
				enemy.knockback = center.direction_to(enemy.position) * push

func _chain_lightning(first: Node2D, muzzle: Vector2) -> void:
	var visited := []
	var previous := muzzle
	var target := first
	for i in range(2 + rank("lightning")):
		if target == null:
			break
		var center: Vector2 = target.position + Vector2(0, -14)
		visited.append(target.get_instance_id())
		visuals.append({"kind": "lightning", "from": previous, "to": center, "life": 0.20, "duration": 0.20, "color": Color("c8b6f0")})
		damage(target, 12.0 + 8.0 * rank("lightning"), Color("c8b6f0"))
		previous = center
		target = null
		var nearest := 130.0 * 130.0
		for candidate in game.enemies:
			if candidate.hp <= 0 or candidate.get_instance_id() in visited:
				continue
			var distance: float = center.distance_squared_to(candidate.position + Vector2(0, -14))
			if distance < nearest:
				nearest = distance
				target = candidate

func pulse(center: Vector2, radius: float, color: Color) -> void:
	visuals.append({"kind": "ring", "position": center, "radius": radius, "life": 0.30, "duration": 0.30, "color": color})

func draw(canvas: Node2D, fraction: float) -> void:
	for orb in orbs:
		var p: Vector2 = Vector2(orb.previous).lerp(orb.position, fraction).round()
		canvas.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("49375e"))
		canvas.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color("bfa0e6"))
		canvas.draw_rect(Rect2(p - Vector2(2, 2), Vector2(2, 2)), Color("f0dfbf"))
	if shield_ready and game.state != "menu":
		var center: Vector2 = game.player.get_global_transform_interpolated().origin + Vector2(0, -17)
		canvas.draw_arc(center, 27.0, 0, TAU, 16, Color(0.56, 0.83, 0.93, 0.60), 2.0)
	for effect in visuals:
		var color: Color = effect.color
		color.a = effect.life / effect.duration
		if effect.kind == "ring":
			canvas.draw_arc(effect.position, effect.radius * (1.0 - color.a * 0.75), 0, TAU, 16, color, 3.0)
		else:
			var a: Vector2 = effect.from
			var b: Vector2 = effect.to
			var side := (b - a).orthogonal().normalized() * 7
			var points := PackedVector2Array([a, a.lerp(b, 0.3) + side, a.lerp(b, 0.55) - side, a.lerp(b, 0.8) + side, b])
			canvas.draw_polyline(points, color, 3.0)
