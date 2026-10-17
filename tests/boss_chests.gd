extends SceneTree
const Data=preload("res://scripts/game_data.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func total_ranks(stacks: Dictionary) -> int:
	var total:=0
	for value in stacks.values(): total+=int(value)
	return total
func run_checks() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock=999
	var ordinary=game._spawn_enemy(0)
	ordinary.hp=0
	game._remove_dead_enemies()
	assert(game.chests.is_empty(),"Ordinary enemies dropped boss loot")
	var boss=game.encounters.spawn_boss(1)
	boss.position=Vector2(150,0)
	boss.hp=0
	game._remove_dead_enemies()
	assert(game.chests.size()==1 and game.chests[0].position==Vector2(150,0))
	assert(game.gems.any(func(gem):return gem.value==100),"Chest replaced the existing boss XP reward")
	game._remove_dead_enemies()
	assert(game.chests.size()==1,"A dead boss dropped twice")
	game.gems.clear()
	game.experience=7
	var chest=game.chests[0]
	game._update_chests(1)
	assert(not chest.opened and game.state=="playing","Distant chest opens without collection")
	game.toggle_pause()
	var chest_age: float=chest.age
	game._physics_process(2)
	game._update_chests(2)
	assert(chest.age==chest_age,"Loot animation advances during pause")
	game.toggle_pause()
	game.player.position=chest.position
	game._physics_process(0.01)
	assert(chest.opened and game.state=="upgrade" and game.ui.screen=="upgrades")
	assert(game.choices.size()==3 and game.level==1 and game.experience==7 and game.next_level==Data.FIRST_LEVEL_XP)
	assert(not game.level_up_aura.active,"Extra loot pretends to increase the player level")
	var time_before: float=game.elapsed
	var player_position: Vector2=game.player.position
	game._physics_process(3)
	assert(game.elapsed==time_before and game.player.position==player_position and game.chests.size()==1)
	var selected_id: String=game.choices[0].id
	game.select_upgrade(0)
	game.select_upgrade(0)
	assert(game.state=="playing" and total_ranks(game.stacks)==1 and game.stacks[selected_id]==1)
	assert(game.level==1 and game.experience==7 and game.next_level==Data.FIRST_LEVEL_XP,"Chest consumed level progress")
	game._update_chests(1)
	assert(game.chests.is_empty(),"Collected loot can be reopened")
	# Matriarch drops too; unopened chests persist independently until approached.
	for number in [2,3]:
		boss=game.encounters.spawn_boss(number)
		boss.position=Vector2(50+number*50,0)
		boss.hp=0
		game._remove_dead_enemies()
	assert(game.chests.size()==2)
	game.gems.clear()
	for item in game.chests: item.age=1
	game.player.position=Vector2(175,0)
	# Both are within pickup range: only one can be consumed while its cards are open.
	game.experience=game.next_level+5
	game._physics_process(0.01)
	assert(game.state=="upgrade" and game.chests.filter(func(c):return c.opened).size()==1)
	assert(game.level==1 and game.experience==Data.FIRST_LEVEL_XP+5,"A level-up overwrote the chest selection")
	game.select_upgrade(0)
	game.player.position=Vector2.ZERO
	game._physics_process(0.01)
	assert(game.state=="levelup" and game.level==2 and game.experience==5,"Pending XP was lost after the chest reward")
	game._physics_process(0.55)
	game.select_upgrade(0)
	assert(total_ranks(game.stacks)==3,"Chest reward replaced an earned level-up")
	game.return_to_menu()
	assert(game.chests.is_empty())
	game.start_run("wand")
	assert(game.chests.is_empty() and game.stacks.is_empty())
	# Capped cards never appear. With one available buff, the chest offers exactly it.
	for card in Data.UPGRADES: game.stacks[card.id]=card.max_level
	game.stacks.shield=2
	game.buffs.refresh_stats()
	chest=game._drop_boss_chest(Vector2.ZERO)
	game._update_chests(0.4)
	assert(game.choices.size()==1 and game.choices[0].id=="shield")
	game.select_upgrade(0)
	assert(game.stacks.shield==3)
	# A fully capped build receives healing rather than an empty/stuck selection.
	game.health=1
	game._drop_boss_chest(Vector2.ZERO)
	game._update_chests(0.4)
	assert(game.state=="playing" and game.choices.is_empty() and game.health==game.max_health)
	assert(game.level==1 and game.experience==0 and game.next_level==Data.FIRST_LEVEL_XP)
	game.start_run("revolver")
	assert(game.chests.is_empty() and game.stacks.is_empty())
	game.queue_free()
	await process_frame
	print("PASS: one chest per defeated boss of either kind, XP retained, nearby-only pickup, frozen combat, one extra ranked buff without XP/level cost, simultaneous loot/XP, caps/healing fallback and clean reset")
	quit()
