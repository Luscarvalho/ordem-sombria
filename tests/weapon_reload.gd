extends SceneTree
const Data=preload("res://scripts/game_data.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func target_for(game,id: String):
	game.start_run(id)
	game.spawn_clock=999
	game.invincible=999
	var enemy=game._spawn_enemy(0)
	enemy.position=Vector2(100,0)
	enemy.speed=0
	enemy.hp=100000
	enemy.max_hp=enemy.hp
	return enemy
func grant(game,id: String):
	game.state="upgrade"
	game.choices.assign([Data.upgrade(id)])
	game.select_upgrade(0)
func run_checks() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for id in Data.WEAPONS:
		var enemy=target_for(game,id)
		var cycle=game.weapon_cycle
		assert(cycle.ammo==Data.WEAPONS[id].ammo and not game.reload_weapon())
		game.extra_pellets=3
		for shot in range(cycle.capacity):
			var before: int=game.bullets.size()
			game._fire(enemy)
			assert(game.bullets.size()-before==Data.WEAPONS[id].pellets+3)
			assert(cycle.ammo==cycle.capacity-shot-1,"Multishot consumed more than one round")
		assert(cycle.reloading and cycle.ammo==0 and game.ui.ammo_bar.segments==1)
		var count: int=game.bullets.size()
		var shots: int=game.buffs.shots
		game._fire(enemy)
		assert(game.bullets.size()==count and game.buffs.shots==shots,"Empty weapon still fires or triggers on-shot buffs")
		game._update_weapon_cycle(cycle.reload_duration/2,true)
		game.player.animate(0)
		assert(is_equal_approx(cycle.progress(),0.5) and is_equal_approx(game.player.reload_progress,0.5))
		var mount: Dictionary=game.player.Mount.WEAPONS[id]
		var grip: Vector2=game.player.held_weapon.to_global(mount.grip+game.player.held_weapon.offset)
		assert(grip.distance_to(game.player.to_global(game.player.Mount.hand_position(game.player.sprite)))<0.001,"Reload animation detaches the grip")
		var remaining: float=cycle.reload_remaining
		assert(not game.reload_weapon() and cycle.reload_remaining==remaining,"R spam restarts/completes the reload")
		game._update_weapon_cycle(remaining,true)
		assert(not cycle.reloading and cycle.ammo==cycle.capacity)
		game._fire(enemy)
		assert(cycle.ammo==cycle.capacity-1)
		# Partial reload via the actual R input, then through the HUD button.
		var key:=InputEventKey.new()
		key.keycode=KEY_R
		key.pressed=true
		game._unhandled_input(key)
		assert(cycle.reloading)
		game._update_weapon_cycle(cycle.reload_duration,true)
		game._fire(enemy)
		game.ui.ammo_button.pressed.emit()
		assert(cycle.reloading)
		game._update_weapon_cycle(cycle.reload_duration,true)
		# Idle top-up waits for a real opening and is not started with a target present.
		game._fire(enemy)
		game._update_weapon_cycle(2,true)
		assert(not cycle.reloading)
		game._update_weapon_cycle(0.64,false)
		assert(not cycle.reloading)
		game._update_weapon_cycle(0.02,false)
		assert(cycle.reloading)
	# Actual automatic fire repeatedly empties/reloads/resumes at the intended timings.
	var enemy=target_for(game,"revolver")
	game.shot_clock=0
	var last_reload_start:=-1.0
	var completions:=0
	for tick in range(1200):
		var was_reloading: bool=game.weapon_cycle.reloading
		var old_shots: int=game.buffs.shots
		game._physics_process(1.0/120.0)
		if not was_reloading and game.weapon_cycle.reloading: last_reload_start=game.elapsed
		if was_reloading and not game.weapon_cycle.reloading:
			assert(game.elapsed-last_reload_start>=game.weapon_cycle.reload_duration-0.01)
			assert(game.buffs.shots==old_shots+1,"Ready weapon did not resume automatically")
			completions+=1
	assert(completions>=2)
	# Movement and combat time continue during reload; pause and both card sources freeze it.
	enemy=target_for(game,"revolver")
	game._fire(enemy)
	game.reload_weapon()
	Input.action_press("move_right")
	game._physics_process(0.1)
	Input.action_release("move_right")
	assert(game.player.position.x>0 and game.weapon_cycle.reloading)
	var remaining: float=game.weapon_cycle.reload_remaining
	game.toggle_pause()
	game._physics_process(3)
	game._update_weapon_cycle(3,true)
	assert(game.weapon_cycle.reload_remaining==remaining)
	game.toggle_pause()
	game.experience=game.next_level
	game._offer_upgrades()
	game._physics_process(0.55)
	assert(game.weapon_cycle.reload_remaining==remaining)
	game.choices.assign([Data.upgrade("damage")])
	game.select_upgrade(0)
	game._drop_boss_chest(game.player.position)
	game._update_chests(0.4)
	game._physics_process(3)
	assert(game.state=="upgrade" and game.weapon_cycle.reload_remaining==remaining)
	game.choices.assign([Data.upgrade("ammo")])
	game.select_upgrade(0)
	assert(game.weapon_cycle.capacity==8 and game.weapon_cycle.reloading)
	var progress: float=game.weapon_cycle.progress()
	grant(game,"reload")
	assert(is_equal_approx(game.weapon_cycle.reload_duration,1.0))
	assert(is_equal_approx(game.weapon_cycle.progress(),progress),"Buff discarded active reload progress")
	for i in range(2): grant(game,"reload")
	assert(is_equal_approx(game.weapon_cycle.reload_duration,0.75))
	game._update_weapon_cycle(game.weapon_cycle.reload_remaining,true)
	assert(game.weapon_cycle.ammo==8)
	game._fire(enemy)
	var partial: int=game.weapon_cycle.ammo
	grant(game,"damage")
	assert(game.weapon_cycle.ammo==partial,"Unrelated upgrades refill ammo")
	game.return_to_menu()
	assert(not game.weapon_cycle.reloading and game.player.reload_progress<0)
	assert(not game.reload_weapon())
	game.start_run("shotgun")
	assert(game.weapon_cycle.capacity==2 and game.weapon_cycle.ammo==2 and game.weapon_cycle.reload_duration==1.6)
	game.queue_free()
	await process_frame
	print("PASS: six weapon magazines, one ammo per volley, empty/manual/idle reload, no shots during reload, R/HUD controls, wrist animation, automatic resumption, free movement, pause/cards, ammo/reload buffs, preserved progress and clean reset")
	quit()
