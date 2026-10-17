extends SceneTree

const Data = preload("res://scripts/game_data.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	for upgrade in Data.UPGRADES:
		var fresh: Button = game.ui._upgrade_card(upgrade, 0, 0)
		game.ui.root.add_child(fresh)
		var fresh_background: Color = fresh.get_theme_stylebox("normal").background
		var fresh_border: Color = fresh.get_theme_stylebox("normal").border
		var fresh_badge: Label = fresh.find_child("BuffLevel", true, false)
		assert(fresh_badge.text.begins_with("NOVO") and fresh_badge.get_theme_color("font_color") == upgrade.color)
		for level in range(1, upgrade.max_level):
			var evolution: Button = game.ui._upgrade_card(upgrade, level, 1)
			game.ui.root.add_child(evolution)
			assert(evolution.get_theme_stylebox("normal").background != fresh_background)
			assert(evolution.get_theme_stylebox("normal").border != fresh_border)
			assert(evolution.get_theme_stylebox("hover").background != fresh.get_theme_stylebox("hover").background)
			assert(evolution.get_theme_stylebox("pressed").background != fresh.get_theme_stylebox("pressed").background)
			assert(evolution.get_theme_stylebox("focus").border_color == game.ui.EVOLUTION_TINT)
			var badge: Label = evolution.find_child("BuffLevel", true, false)
			assert(badge.text == "EVOLUÇÃO / %d > %d / %d" % [level, level + 1, upgrade.max_level])
			assert(badge.get_theme_color("font_color") == game.ui.EVOLUTION_TINT)
			var sprite = evolution.find_child("BuffSprite", true, false)
			assert(sprite.accent == upgrade.color and sprite.buff == upgrade.id, "Upgrade tint replaces the buff's recognizable art color")
			var pips = evolution.find_child("BuffLevels", true, false)
			assert(pips.value == level + 1 and pips.color == game.ui.EVOLUTION_TINT)
			evolution.free()
		assert(upgrade.color == fresh_badge.get_theme_color("font_color"), "Drawing an evolution mutates new cards")
		fresh.free()
	for chest in [false, true]:
		game.start_run("wand")
		game.stacks.damage = 1
		game.choices.assign([Data.upgrade("damage"), Data.upgrade("magnet")])
		game.state = "upgrade"
		game.ui.show_upgrades(game.choices, false, chest)
		var evolution: Button = game.ui.content.find_child("Upgrade_damage", true, false)
		var fresh: Button = game.ui.content.find_child("Upgrade_magnet", true, false)
		assert(evolution.get_theme_stylebox("normal").background != fresh.get_theme_stylebox("normal").background)
		evolution.pressed.emit()
		assert(game.stacks.damage == 2 and game.state == "playing")
		game.choices.assign([Data.upgrade("magnet")])
		game.state = "upgrade"
		game.ui.show_upgrades(game.choices, false, chest)
		fresh = game.ui.content.find_child("Upgrade_magnet", true, false)
		fresh.pressed.emit()
		assert(game.stacks.magnet == 1 and game.state == "playing")
	game.queue_free()
	await process_frame
	print("PASS: distinct new/evolution colors for all 22 buff cards and every upgradable rank, readable evolution labels, normal/hover/pressed/focus states, preserved icon colors and working XP/chest choices")
	quit()
