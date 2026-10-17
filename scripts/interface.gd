extends CanvasLayer
## Shared pixel-art theme for HUD, weapon selection, upgrades and touch controls.

const Data = preload("res://scripts/game_data.gd")
const Pixel = preload("res://scripts/pixel_theme.gd")
const Icon = preload("res://scripts/pixel_icon.gd")
const Meter = preload("res://scripts/pixel_bar.gd")
const BuffIcon = preload("res://scripts/buff_icon.gd")
const HUNTER_FRAMES = preload("res://assets/animations/hunter-final-v8.tres")
const INK := Color("211b2b")
const PAPER := Color("f0dfbf")
const MUTED := Color("ac9ba9")
const AMBER := Color("efb775")
const MINT := Color("83c9b3")
const ROSE := Color("d67d8a")
var game: Node2D
var root: Control
var hud: MarginContainer
var overlay: ColorRect
var center: CenterContainer
var content: VBoxContainer
var health_bar: Meter
var xp_bar: Meter
var health_label: Label
var level_label: Label
var status_label: Label
var weapon_label: Label
var ammo_button: Button
var ammo_bar: Meter
var joystick: Control
var footer: Label
var screen := "home"
var settings_return := "home"
var overlay_fade: Tween
var encounter_label: Label
var boss_panel: PanelContainer
var boss_name: Label
var boss_health: Meter

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.theme = Pixel.theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hud()
	joystick = Control.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.draw.connect(_draw_joystick)
	root.add_child(joystick)
	overlay = ColorRect.new()
	overlay.color = Color(0.055, 0.04, 0.085, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_overlay)
	overlay.resized.connect(overlay.queue_redraw)
	root.add_child(overlay)
	center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

func _process(_delta: float) -> void:
	joystick.queue_redraw()

func _build_hud() -> void:
	hud = MarginContainer.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for edge in ["left", "right", "top", "bottom"]:
		hud.add_theme_constant_override("margin_" + edge, 8)
	root.add_child(hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	hud.add_child(row)
	var left := _hud_panel(row, 200)
	var health_row := HBoxContainer.new()
	health_row.add_theme_constant_override("separation", 4)
	left.add_child(health_row)
	health_row.add_child(_icon("vitality", Vector2(16, 16), ROSE))
	health_label = _label("VIDA 100/100", 12, PAPER)
	health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_row.add_child(health_label)
	ammo_button = _button("6/6", 10)
	ammo_button.name = "AmmoReloadButton"
	ammo_button.custom_minimum_size = Vector2(56, 18)
	ammo_button.tooltip_text = "Recarregar: R ou clique aqui. Reserva ilimitada."
	ammo_button.pressed.connect(game.reload_weapon)
	health_row.add_child(ammo_button)
	health_bar = _bar(ROSE)
	left.add_child(health_bar)
	health_bar.custom_minimum_size.y = 10
	weapon_label = _label("REVÓLVER / MÉDIO-LONGO", 10, AMBER)
	left.add_child(weapon_label)
	ammo_bar = _bar(AMBER)
	ammo_bar.name = "AmmoBar"
	left.add_child(ammo_bar)
	ammo_bar.custom_minimum_size.y = 4
	var middle := _hud_panel(row, 0)
	middle.get_parent().get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	middle.add_child(progress_row)
	level_label = _label("NÍVEL 1", 12, MINT)
	progress_row.add_child(level_label)
	status_label = _label("00:00 / 0 ABATES / FASE 1", 10, PAPER)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_row.add_child(status_label)
	xp_bar = _bar(MINT)
	middle.add_child(xp_bar)
	xp_bar.custom_minimum_size.y = 10
	encounter_label = _label("ARANHAS / BOSS 05:00", 10, AMBER)
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(encounter_label)
	var pause := _button("II PAUSAR", 12)
	pause.custom_minimum_size = Vector2(104, 36)
	if DisplayServer.is_touchscreen_available():
		pause.custom_minimum_size.y = 44
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause.pressed.connect(game.toggle_pause)
	row.add_child(pause)
	footer = _label("WASD / SETAS   |   TIRO AUTOMÁTICO   |   R: RECARREGAR   |   P / ESC: PAUSAR", 12, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -26
	footer.offset_bottom = -10
	if DisplayServer.is_touchscreen_available():
		footer.text = "ARRASTE À ESQUERDA PARA MOVER   |   TIRO AUTOMÁTICO"
	root.add_child(footer)
	_build_encounter_hud()

func _build_encounter_hud() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.name = "BossHealthPanel"
	boss_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_panel.offset_left = -260
	boss_panel.offset_right = 260
	boss_panel.offset_top = 76
	boss_panel.offset_bottom = 134
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_theme_stylebox_override("panel", Pixel.panel(INK, ROSE))
	root.add_child(boss_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_child(column)
	boss_name = _label("CHEFE", 16, PAPER)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(boss_name)
	boss_health = _bar(ROSE)
	column.add_child(boss_health)
	boss_panel.hide()

func _hud_panel(parent: Control, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	var style := Pixel.panel(INK, Color("665069"))
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	return column

func _bar(color: Color) -> Meter:
	var bar := Meter.new()
	bar.color = color
	return bar

func _new_overlay(eyebrow: String, title: String, subtitle: String, title_size: int = 48, width: float = 860) -> void:
	_reset_overlay_fade()
	boss_panel.hide()
	overlay.show()
	footer.hide()
	for child in center.get_children():
		center.remove_child(child)
		child.queue_free()
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.custom_minimum_size.x = width
	center.add_child(content)
	var small := _label("- " + eyebrow + " -", 12, AMBER)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(small)
	var heading := _label(title, title_size, PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_shadow_color", Color("713f51"))
	heading.add_theme_constant_override("shadow_offset_x", 4)
	heading.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(heading)
	var description := _label(subtitle, 16, MUTED)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(description)

func show_menu() -> void:
	screen = "home"
	game.state = "menu"
	game.music.set_context("menu")
	game.touch_index = -1
	hud.hide()
	_new_overlay("SOBREVIVA. ESCOLHA. EVOLUA.", "HORDA SOMBRIA", "A NOITE COMEÇA COM VOCÊ.")
	var body := HBoxContainer.new()
	body.name = "HomeBody"
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 32)
	content.add_child(body)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(192, 220)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_theme_stylebox_override("panel", Pixel.panel(Color("17121f"), Color("70566e")))
	body.add_child(portrait)
	var art := TextureRect.new()
	art.texture = HUNTER_FRAMES.get_frame_texture("idle_down", 0)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(art)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.custom_minimum_size.x = 300
	body.add_child(buttons)
	var play := _menu_button("[ JOGAR ]", "PlayButton", show_weapon_selection)
	buttons.add_child(play)
	buttons.add_child(_menu_button("COMO JOGAR", "HelpButton", show_help))
	buttons.add_child(_menu_button("CONFIGURAÇÕES", "SettingsButton", show_settings))
	if not OS.has_feature("web"):
		buttons.add_child(_menu_button("SAIR", "QuitButton", _quit_game))
	call_deferred("_focus_if_visible", play)
	var note := _label("CADA CAÇADA, UMA NOVA COMBINAÇÃO.", 12, MINT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)

func show_weapon_selection() -> void:
	screen = "weapons"
	game.state = "menu"
	hud.hide()
	_new_overlay("PREPARE-SE PARA A NOITE", "ESCOLHA SUA ARMA", "UMA CAÇADORA. TRÊS CAMINHOS PARA SOBREVIVER.", 32)
	var row := _card_row()
	for id in ["revolver", "shotgun", "wand"]:
		var card := _weapon_card(id)
		card.pressed.connect(game.start_run.bind(id))
		row.add_child(card)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 16)
	content.add_child(navigation)
	navigation.add_child(_menu_button("< VOLTAR", "BackButton", show_menu, 32))
	var note := _label("ATRIBUTOS INICIAIS / ALCANCE EM UNIDADES DO JOGO", 12, MINT)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	navigation.add_child(note)
	call_deferred("_focus_if_visible", row.get_child(0))

func show_help() -> void:
	screen = "help"
	game.state = "menu"
	hud.hide()
	_new_overlay("ANTES DA PRIMEIRA CAÇADA", "COMO JOGAR", "MOVA-SE, COLETE ALMAS E ENCONTRE SUA COMBINAÇÃO.", 32, 780)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Pixel.panel(INK, Color("70566e")))
	content.add_child(panel)
	var instructions := VBoxContainer.new()
	instructions.add_theme_constant_override("separation", 12)
	panel.add_child(instructions)
	var steps := [
		["MOVA-SE", "Use WASD ou as setas. No celular, arraste no lado esquerdo."],
		["DISPARE", "A arma mira e atira automaticamente. Cada salva usa uma munição."],
		["RECARREGUE", "R ou clique na munição. Recarrega ao esvaziar e nas brechas sem alvo."],
		["EVOLUA", "Colete almas verdes. A cada nível, escolha uma carta de melhoria."],
		["SOBREVIVA", "Chefes a cada 5 minutos. Use P, Esc ou PAUSAR para respirar."],
	]
	for step in steps:
		instructions.add_child(_label(step[0], 12, AMBER))
		var description := _label(step[1], 16, PAPER)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instructions.add_child(description)
	var back := _menu_button("< VOLTAR AO MENU", "BackButton", show_menu, 44)
	content.add_child(back)
	call_deferred("_focus_if_visible", back)

func _focus_if_visible(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree():
		button.grab_focus()

func go_back() -> void:
	if screen == "settings" and settings_return == "pause":
		show_pause()
	elif screen in ["weapons", "help", "settings"]:
		show_menu()

func show_settings() -> void:
	settings_return = "pause" if game.state == "paused" else "home"
	screen = "settings"
	_new_overlay("DO SEU JEITO", "CONFIGURAÇÕES", "AJUSTE AS MÚSICAS E OS EFEITOS.", 32, 700)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Pixel.panel(INK, Color("70566e")))
	content.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var toggle := _button("", 16)
	toggle.name = "MusicToggle"
	toggle.custom_minimum_size.y = 48
	toggle.toggle_mode = true
	toggle.button_pressed = game.music.enabled
	_music_toggle_text(toggle, game.music.enabled)
	toggle.toggled.connect(func(value: bool):
		game.music.set_enabled(value)
		_music_toggle_text(toggle, value)
	)
	column.add_child(toggle)
	_volume_control(column, "menu", "MÚSICA DO MENU")
	_volume_control(column, "game", "MÚSICA DA PARTIDA")
	_volume_control(column, "effects", "EFEITOS SONOROS")
	column.add_child(_menu_button("[ TESTAR SOM ]", "TestSoundButton", func(): game.music.play_sfx("revolver"), 36))
	var note := _label("AS ALTERAÇÕES SÃO SALVAS AUTOMATICAMENTE.", 12, MINT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)
	var back := _menu_button("< VOLTAR À PAUSA" if settings_return == "pause" else "< VOLTAR AO MENU", "BackButton", go_back, 48)
	content.add_child(back)
	call_deferred("_focus_if_visible", toggle)

func _music_toggle_text(button: Button, value: bool) -> void:
	button.text = "[ X ] MÚSICA LIGADA" if value else "[   ] MÚSICA DESLIGADA"

func _volume_control(parent: Control, id: String, title: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var label := _label(title, 16, PAPER)
	label.custom_minimum_size.x = 240
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = id.capitalize() + "Volume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = game.music.volumes[id] * 100
	slider.custom_minimum_size = Vector2(240, 48)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.add_theme_stylebox_override("slider", Pixel.panel(Color("17121f"), Color("70566e"), false))
	slider.add_theme_stylebox_override("grabber_area", Pixel.panel(MINT.darkened(0.5), MINT, false))
	slider.add_theme_stylebox_override("grabber_area_highlight", Pixel.panel(MINT.darkened(0.3), MINT, false))
	var image := Image.create_empty(12, 24, false, Image.FORMAT_RGBA8)
	image.fill(AMBER)
	image.fill_rect(Rect2i(2, 2, 8, 20), PAPER)
	image.fill_rect(Rect2i(5, 6, 2, 12), INK)
	var grabber := ImageTexture.create_from_image(image)
	for icon in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(icon, grabber)
	slider.add_theme_constant_override("grabber_offset", 0)
	row.add_child(slider)
	var percent := _label("%d%%" % slider.value, 16, AMBER)
	percent.custom_minimum_size.x = 64
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(percent)
	slider.value_changed.connect(func(value: float):
		game.music.set_volume(id, value / 100.0)
		percent.text = "%d%%" % value
	)

func _quit_game() -> void:
	get_tree().quit()

func _menu_button(text: String, node_name: String, action: Callable, height: float = 56) -> Button:
	var button := _button(text, 16)
	button.name = node_name
	button.custom_minimum_size.y = height
	button.pressed.connect(action)
	return button

func show_upgrades(upgrades: Array[Dictionary], animate_entry: bool = false, from_chest: bool = false) -> void:
	screen = "upgrades"
	if from_chest:
		_new_overlay("RECOMPENSA DO CHEFE", "BAÚ DO CHEFE", "ESCOLHA UM BUFF EXTRA PARA ESTA CAÇADA.", 32)
	else:
		_new_overlay("UM NOVO PODER DESPERTA", "NÍVEL %d" % game.level, "ESCOLHA UM NOVO BUFF OU EVOLUA UM DOS SEUS.", 32)
	var row := _card_row()
	for i in range(upgrades.size()):
		var upgrade: Dictionary = upgrades[i]
		var count: int = game.stacks.get(upgrade.id, 0)
		var card := _upgrade_card(upgrade, count, i)
		card.pressed.connect(game.select_upgrade.bind(i))
		row.add_child(card)
	if row.get_child_count() > 0:
		call_deferred("_focus_if_visible", row.get_child(0))
	if animate_entry:
		overlay.modulate.a = 0.0
		overlay_fade = create_tween()
		overlay_fade.tween_property(overlay, "modulate:a", 1.0, 0.12)

func _reset_overlay_fade() -> void:
	if overlay_fade != null and overlay_fade.is_valid():
		overlay_fade.kill()
	overlay.modulate = Color.WHITE

func show_pause() -> void:
	screen = "pause"
	_new_overlay("RESPIRE UM POUCO", "JOGO PAUSADO", "A CAÇADA ESPERA POR VOCÊ.")
	content.add_child(_icon("magnet", Vector2(64, 64), MINT))
	var button := _button("[ CONTINUAR ]", 24)
	button.custom_minimum_size.y = 64
	button.pressed.connect(game.toggle_pause)
	content.add_child(button)
	content.add_child(_menu_button("CONFIGURAÇÕES", "SettingsButton", show_settings, 48))
	content.add_child(_menu_button("MENU PRINCIPAL", "HomeButton", game.return_to_menu, 44))

func show_death() -> void:
	screen = "death"
	_new_overlay("A NOITE COBROU SEU PREÇO", "FIM DA CAÇADA", "%s SOBREVIVIDOS / %d ABATES / NÍVEL %d" % [game.time_label(), game.kills, game.level])
	content.add_child(_icon("skull", Vector2(64, 64), ROSE))
	var retry := _button("[ TENTAR NOVAMENTE ]", 24)
	retry.custom_minimum_size.y = 64
	retry.pressed.connect(game.start_run.bind(game.weapon_id))
	content.add_child(retry)
	var menu := _button("MENU PRINCIPAL", 16)
	menu.name = "HomeButton"
	menu.custom_minimum_size.y = 52
	menu.pressed.connect(game.return_to_menu)
	content.add_child(menu)

func hide_overlay() -> void:
	_reset_overlay_fade()
	screen = "playing"
	overlay.hide()
	hud.show()
	footer.show()
	update_weapon_hud()

func update_hud() -> void:
	health_label.text = "VIDA %d/%d" % [ceili(game.health), ceili(game.max_health)]
	health_bar.max_value = game.max_health
	health_bar.value = game.health
	xp_bar.max_value = game.next_level
	xp_bar.value = game.experience
	level_label.text = "NÍVEL %d" % game.level
	update_weapon_hud()
	status_label.text = "%s / %d ABATES / FASE %d" % [game.time_label(), game.kills, 1 + game.Waves.phase_index(game.elapsed)]
	weapon_label.text = "%s / %s" % [Data.WEAPONS[game.weapon_id].title, Data.WEAPONS[game.weapon_id].range_label]
	var remaining := maxi(0, ceili(game.boss_clock - game.elapsed))
	var phase: Dictionary = game.Waves.PHASES[game.Waves.phase_index(game.elapsed)]
	encounter_label.text = "%s / BOSS %02d:%02d" % [phase.name, remaining / 60, remaining % 60]
	var boss: Node2D = game.encounters.current_boss()
	boss_panel.visible = boss != null and game.state in ["playing", "levelup"]
	if boss != null:
		boss_name.text = boss.brain.title + (" / FÚRIA" if boss.brain.enraged else "")
		boss_health.max_value = boss.max_hp
		boss_health.value = boss.hp

func update_weapon_hud() -> void:
	var cycle = game.weapon_cycle
	ammo_button.text = ("REC %.1f" % cycle.reload_remaining).replace(".", ",") if cycle.reloading else "%d/%d" % [cycle.ammo, cycle.capacity]
	ammo_button.disabled = game.state != "playing" or cycle.reloading or cycle.ammo == cycle.capacity
	ammo_bar.color = MINT if game.weapon_id == "wand" else AMBER
	ammo_bar.max_value = 1.0 if cycle.reloading else float(cycle.capacity)
	ammo_bar.value = cycle.progress() if cycle.reloading else float(cycle.ammo)
	ammo_bar.segments = 1 if cycle.reloading else cycle.capacity

func _card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	return row

func _weapon_card(id: String) -> Button:
	var weapon: Dictionary = Data.WEAPONS[id]
	var button := _button("", 16)
	button.name = "Weapon_" + id
	button.tooltip_text = weapon.description + "\nPerfuração: alvos extras atingidos por cada projétil."
	button.custom_minimum_size = Vector2(276, 352)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 14)
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	column.add_child(_label(weapon.tag, 12, weapon.color))
	column.add_child(_label(weapon.title, 24, PAPER))
	var art := PanelContainer.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", Pixel.panel(Color("17121f"), weapon.color.darkened(0.55), false))
	var sprite := Icon.new()
	sprite.name = "WeaponArt"
	sprite.icon = id
	sprite.large_weapon = true
	sprite.accent = weapon.color
	sprite.custom_minimum_size = Vector2(0, 88)
	art.add_child(sprite)
	column.add_child(art)
	var stats := VBoxContainer.new()
	stats.name = "Stats"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_constant_override("separation", 3)
	stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stats)
	for attribute in Data.weapon_stats(id):
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var caption := _label(attribute.label, 12, MUTED)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(caption)
		row.add_child(_label(attribute.value, 12, weapon.color))
		stats.add_child(row)
	var line := ColorRect.new()
	line.color = Color("554055")
	line.custom_minimum_size.y = 2
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	var action := _label("[ INICIAR CAÇADA ]", 12, PAPER)
	action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(action)
	return button

func _upgrade_card(upgrade: Dictionary, current: int, index: int) -> Button:
	var accent: Color = upgrade.color
	var button := _button("", 16)
	button.name = "Upgrade_" + upgrade.id
	button.custom_minimum_size = Vector2(276, 372)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 14)
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	column.add_child(_label(upgrade.tag, 12, accent))
	var name_label := _label(upgrade.title.to_upper(), 20, PAPER)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 48
	column.add_child(name_label)
	var art := PanelContainer.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", Pixel.panel(Color("17121f"), accent.darkened(0.6), false))
	column.add_child(art)
	var sprite := BuffIcon.new()
	sprite.name = "BuffSprite"
	sprite.buff = upgrade.id
	sprite.accent = accent
	sprite.custom_minimum_size = Vector2(0, 64)
	art.add_child(sprite)
	var next: int = mini(current + 1, upgrade.max_level)
	var level_text := "NOVO / NÍVEL 1 DE %d" % upgrade.max_level if current == 0 else "NÍVEL %d > %d / %d" % [current, next, upgrade.max_level]
	var level_badge := _label(level_text, 12, accent)
	level_badge.name = "BuffLevel"
	column.add_child(level_badge)
	var pips := Meter.new()
	pips.name = "BuffLevels"
	pips.color = accent
	pips.segments = upgrade.max_level
	pips.max_value = upgrade.max_level
	pips.value = next
	column.add_child(pips)
	var body := _label(Data.upgrade_preview(upgrade.id, current, {"stacks": game.stacks, "weapon": game.weapon_id}), 16, MUTED)
	body.name = "BuffPreview"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var line := ColorRect.new()
	line.color = Color("554055")
	line.custom_minimum_size.y = 2
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	column.add_child(_label("[ %s %d ]" % ["ADQUIRIR" if current == 0 else "EVOLUIR", index + 1], 12, PAPER))
	return button

func _button(text: String, size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", AMBER)
	button.add_theme_stylebox_override("normal", Pixel.panel(INK, Color("70566e")))
	button.add_theme_stylebox_override("hover", Pixel.panel(Color("332335"), AMBER))
	button.add_theme_stylebox_override("pressed", Pixel.panel(Color("3b2d39"), MINT))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = AMBER
	focus.set_border_width_all(2)
	focus.anti_aliasing = false
	button.add_theme_stylebox_override("focus", focus)
	return button

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _icon(icon_name: String, minimum: Vector2, accent: Color) -> Control:
	var icon := Icon.new()
	icon.icon = icon_name
	icon.accent = accent
	icon.custom_minimum_size = minimum
	return icon

func _draw_overlay() -> void:
	var dimensions := overlay.size
	var dim := Color("2a2135")
	for x in range(24, int(dimensions.x), 48):
		for y in range(24, int(dimensions.y), 48):
			if (x * 3 + y * 7) % 5 == 0:
				overlay.draw_rect(Rect2(x, y, 2, 2), dim)
	for corner in [Vector2(12, 12), Vector2(dimensions.x - 12, 12), Vector2(12, dimensions.y - 12), dimensions - Vector2(12, 12)]:
		var direction := Vector2(1 if corner.x < dimensions.x / 2 else -1, 1 if corner.y < dimensions.y / 2 else -1)
		overlay.draw_rect(Rect2(corner + Vector2(minf(0, direction.x * 32), 0), Vector2(32, 2)), AMBER.darkened(0.55))
		overlay.draw_rect(Rect2(corner + Vector2(0, minf(0, direction.y * 32)), Vector2(2, 32)), AMBER.darkened(0.55))

func _draw_joystick() -> void:
	if game.state != "playing" or game.touch_index < 0:
		return
	var origin: Vector2 = game.touch_origin.round()
	var stick: Vector2 = (origin + (game.touch_position - origin).limit_length(55)).round()
	Pixel.panel(Color(0.1, 0.08, 0.15, 0.65), Color("72566f")).draw(joystick.get_canvas_item(), Rect2(origin - Vector2(60, 60), Vector2(120, 120)))
	Pixel.panel(Color("41364c"), MINT).draw(joystick.get_canvas_item(), Rect2(stick - Vector2(20, 20), Vector2(40, 40)))
