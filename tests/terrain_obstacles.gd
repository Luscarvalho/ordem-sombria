extends SceneTree
const Terrain=preload("res://scripts/terrain_obstacles.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func clear_of_terrain(terrain: Node2D,point: Vector2,radius: float) -> bool:
	for data in terrain.nearby(point,point,radius):
		if point.distance_to(data.position)<radius+float(data.radius)-0.001: return false
	return true
func run_checks() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock=999
	var terrain: Node2D=game.obstacles
	var other:=Terrain.new()
	var kinds:={}
	var selected:={}
	for x in range(-5,6):
		for y in range(-5,6):
			var cell:=Vector2i(x,y)
			var data: Dictionary=terrain.obstacle_at(cell)
			assert(data==other.obstacle_at(cell),"World generation depends on traversal order")
			if data.is_empty(): continue
			kinds[data.kind]=true
			assert(Vector2(data.position).length()-float(data.radius)>Terrain.SPAWN_CLEARANCE)
			var start: Vector2=data.position-Vector2(90,0)
			var hit: Dictionary=terrain.cast(start,Vector2(180,0),12)
			if selected.is_empty() and data.position.length()>400 and not hit.obstacle.is_empty() and hit.obstacle.cell==cell:
				selected=data
	assert(kinds.size()==3 and not selected.is_empty())
	var populated := 0
	var previous_populated := 0
	for x in range(10,51):
		for y in range(10,51):
			var random := RandomNumberGenerator.new()
			random.seed = (x*73856093) ^ (y*19349663) ^ 813337
			var roll := random.randf()
			if roll < 0.76:
				previous_populated += 1
			var data := other.obstacle_at(Vector2i(x,y))
			if data.is_empty(): continue
			populated += 1
			assert(roll < Terrain.SPAWN_CHANCE)
			var previous_position := (Vector2(x,y)+Vector2.ONE*0.5)*Terrain.CELL+Vector2(random.randf_range(-56,56),random.randf_range(-56,56))
			assert(data.position == previous_position.round(), "Lower density relocates surviving obstacles")
	assert(populated > previous_populated*0.40 and populated < previous_populated*0.55, "Obstacle reduction is not close to half the previous density")
	other.free()
	var center: Vector2=selected.position
	var start:=center-Vector2(90,0)
	var combined: float=selected.radius+12.0
	# A large displacement must stop at the first face, rather than tunnel through it.
	game.player.position = start
	terrain.ensure_collision(start, start + Vector2(1800, 0), 12)
	await physics_frame
	game.player.move_with_velocity(Vector2(108000, 0))
	var stopped: Vector2 = game.player.position
	assert(game.player.get_slide_collision_count() > 0 and game.player.get_slide_collision(0).get_collider() == terrain.collision_cells[selected.cell])
	assert(stopped.x > start.x and stopped.x <= center.x-combined+0.5 and absf(stopped.y-center.y)<0.01, "Native sweep failed to stop before the obstacle: %s" % stopped)
	assert(clear_of_terrain(terrain,stopped,12))
	var sliding_start:=center-Vector2(combined+0.1,15)
	game.player.position = sliding_start
	await physics_frame
	game.player.move_with_velocity(Vector2(1800, 3300))
	var slid: Vector2 = game.player.position
	assert(slid.y>sliding_start.y+10 and clear_of_terrain(terrain,slid,12),"Diagonal input does not slide around the obstacle")
	assert(clear_of_terrain(terrain,terrain.safe_position(center,32),32),"Boss-sized spawn stays embedded")
	# The actual player movement and animation stop at the obstruction.
	game.player.position=start
	game.player_velocity=Vector2.ZERO
	game.invincible=100
	game.shot_clock=999
	Input.action_press("move_right")
	for tick in range(90):
		await physics_frame
		game._physics_process(1.0/60.0)
	Input.action_release("move_right")
	assert(clear_of_terrain(terrain,game.player.position,game.player.radius))
	assert(game.player.position.x<center.x and not game.player.moving,"Blocked player walks through the obstacle or keeps running in place")
	# A pursuing spider routes around the same rock through the production AI/movement.
	game.player.position=center+Vector2(90,0)
	var pursuer=game._spawn_enemy(0)
	pursuer.position=start
	for tick in range(900):
		await physics_frame
		game._update_enemies(1.0/60.0)
		assert(clear_of_terrain(terrain,pursuer.position,pursuer.radius),"Enemy clips an obstacle")
		if pursuer.position.distance_to(game.player.position)<32: break
	assert(pursuer.position.distance_to(game.player.position)<32,"Pursuer remains trapped behind the obstacle")
	# The auto-aim skips covered targets, and both kinds of projectile stop at cover.
	game.player.position=start
	pursuer.position=center+Vector2(90,0)
	assert(game._nearest_enemy()==null,"Auto-aim picks a target behind cover")
	var health_before: float=pursuer.hp
	game._fire(pursuer)
	game._update_bullets(1.0)
	assert(game.bullets.is_empty() and pursuer.hp==health_before,"Player projectile crossed cover")
	game.player.position=center+Vector2(90,0)
	game.invincible=0
	var player_health: float=game.health
	game.encounters._add_bullet(start+Vector2(0,-15),Vector2(400,0),12,false)
	game.encounters.update_projectiles(1.0)
	assert(game.encounters.hostile_bullets.is_empty() and game.health==player_health,"Enemy projectile crossed cover")
	# Normal, pack, boss and summoned spawning all use the same free-footprint resolver.
	for type in [0,1,2,3,4,5,6]:
		var enemy=game._spawn_enemy(type)
		assert(clear_of_terrain(terrain,enemy.position,enemy.radius))
	game.encounters.summons.append({"position":center,"type":4})
	game.encounters.flush_summons()
	assert(clear_of_terrain(terrain,game.enemies[-1].position,game.enemies[-1].radius))
	var saved: Dictionary=terrain.obstacle_at(selected.cell).duplicate(true)
	terrain.follow(Vector2(30000,-30000))
	assert(terrain.visible_cells.size()<=99 and terrain.records.size()<=625)
	terrain.follow(Vector2.ZERO)
	assert(saved==terrain.obstacle_at(selected.cell),"Returning to an area moved its obstacles")
	assert(game.actors.y_sort_enabled and terrain.visible_cells.values()[0].get_parent()==game.actors)
	game.queue_free()
	await process_frame
	print("PASS: approximately half the previous obstacle density, preserved prop positions, deterministic pixel props, clear spawn, continuous collision, wall sliding, actual player/enemy movement, pursuit around cover, blocked aim/projectiles, safe spawns, bounded streaming and actor depth sorting")
	quit()
