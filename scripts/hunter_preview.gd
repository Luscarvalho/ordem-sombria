extends Control
## Standalone F6 animation viewer. Uses the same actor, art, sockets and timing as gameplay.
const Actor = preload("res://scripts/actor.gd")
const HunterScene = preload("res://scenes/characters/hunter.tscn")
const Pixel = preload("res://scripts/pixel_theme.gd")
const PREVIOUS_FRAMES = preload("res://assets/animations/hunter-directions-v6.tres")
const DIRECTIONS := [Vector2.RIGHT, Vector2(1,1), Vector2.DOWN, Vector2(-1,1), Vector2.LEFT, Vector2(-1,-1), Vector2.UP, Vector2(1,-1)]
const TITLES := ["DIREITA", "BAIXO / DIREITA", "BAIXO", "BAIXO / ESQUERDA", "ESQUERDA", "CIMA / ESQUERDA", "CIMA", "CIMA / DIREITA"]
const SHORT_TITLES := ["DIR", "BAIXO/DIR", "BAIXO", "BAIXO/ESQ", "ESQ", "CIMA/ESQ", "CIMA", "CIMA/DIR"]
const WEAPONS := ["revolver", "shotgun", "wand", ""]
const SPEEDS := [0.25, 0.5, 1.0, 1.5, 2.0]
const PAPER := Color("f0dfbf")
const MINT := Color("83c9b3")
const MUTED := Color("ac9ba9")

@export_enum("Todas as direções", "Uma direção", "Antes e depois") var display_mode := 0
@export_range(0, 7, 1) var direction_index := 0
@export var travel_preview := false

var actors: Array[Node2D] = []
var captions: Array[Label] = []
var direction_labels: Array[Label] = []
var stage: Control
var pause_button: Button
var pose_button: Button
var playing := true
var walking := true
var playback_speed := 1.0
var selected_weapon := "revolver"
var travel_button: Button
var travel_clock := 0.0
var stage_origins: Array[Vector2] = []
var stage_anchors: Array[Node2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = Pixel.theme()
	_build_interface()
	_build_actors()
	_layout_actors()
	_update_captions()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("0e141a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := _label("CAÇADORA / " + (TITLES[direction_index] if display_mode == 1 else "ANTES E DEPOIS" if display_mode == 2 else "OITO DIREÇÕES"), 20, PAPER)
	column.add_child(title)
	var subtitle := "ANIMAÇÃO COMPLETA EM LOOP / MESMOS SPRITES E RITMO DA PARTIDA"
	if display_mode == 2:
		subtitle = "ANTERIOR EM CIMA / NOVA FOLHA EMBAIXO / CICLOS COMPLETOS EM LOOP"
	column.add_child(_label(subtitle, 10, MUTED))
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	column.add_child(toolbar)
	pause_button = _button("PAUSAR", toggle_playback)
	toolbar.add_child(pause_button)
	toolbar.add_child(_button("+1 QUADRO", step_frame))
	pose_button = _button("VER PARADA", toggle_pose)
	toolbar.add_child(pose_button)
	toolbar.add_child(_button("REINICIAR", restart_cycle))
	var speed := OptionButton.new()
	speed.focus_mode = Control.FOCUS_NONE
	speed.add_theme_font_size_override("font_size", 12)
	for text in ["0,25x", "0,5x", "1x", "1,5x", "2x"]:
		speed.add_item(text)
	speed.select(2)
	speed.item_selected.connect(func(index: int): playback_speed = SPEEDS[index])
	toolbar.add_child(speed)
	var weapon := OptionButton.new()
	weapon.focus_mode = Control.FOCUS_NONE
	weapon.add_theme_font_size_override("font_size", 12)
	for text in ["REVÓLVER", "ESCOPETA", "CAJADO", "SEM ARMA"]:
		weapon.add_item(text)
	weapon.item_selected.connect(func(index: int): set_weapon(WEAPONS[index]))
	toolbar.add_child(weapon)
	travel_button = _button("NO LUGAR" if travel_preview else "DESLOCAR",toggle_travel)
	toolbar.add_child(travel_button)
	stage = Control.new()
	stage.name = "AnimationStage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size = Vector2(0, 280)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.draw.connect(_draw_stage)
	stage.resized.connect(_layout_actors)
	column.add_child(stage)
	column.add_child(_label("ESPAÇO: PAUSAR / CONTINUAR   |   SETA DIREITA: +1 QUADRO   |   R: REINICIAR", 10, MUTED))

func _build_actors() -> void:
	var count := 1 if display_mode == 1 else 16 if display_mode == 2 else 8
	for i in range(count):
		var anchor := Node2D.new()
		anchor.name = "HunterStage%d" % i
		stage.add_child(anchor)
		stage_anchors.append(anchor)
		var actor := HunterScene.instantiate()
		actor.name = "Hunter%d" % i
		actor.collision_layer = 0
		actor.collision_mask = 0
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		anchor.add_child(actor)
		actor.hurtbox.collision_layer = 0
		if display_mode == 2 and i < 8:
			actor.sprite.sprite_frames = PREVIOUS_FRAMES
			actor.base_scale = actor._height() / PREVIOUS_FRAMES.get_frame_texture("idle", 0).get_height()
		actors.append(actor)
		stage_origins.append(Vector2.ZERO)
		var direction_label := _label(TITLES[_sector(i)], 10, MUTED)
		direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if display_mode == 2:
			direction_label.text = ("ANTERIOR\n" if i < 8 else "NOVA FOLHA\n") + SHORT_TITLES[_sector(i)]
			direction_label.modulate = MUTED if i < 8 else MINT
		stage.add_child(direction_label)
		direction_labels.append(direction_label)
		var caption := _label("", 10, MINT)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage.add_child(caption)
		captions.append(caption)
		restart_actor(actor, i)

func restart_actor(actor: Node2D, index: int) -> void:
	actor.reset_motion()
	actor.weapon = selected_weapon
	var direction: Vector2 = DIRECTIONS[_sector(index)].normalized()
	actor.aiming = true
	actor.aim = direction
	actor.body_angle = direction.angle()
	actor.visual_angle = direction.angle()
	actor.moving = walking
	actor.motion = direction * Actor.REFERENCE_SPEEDS[0] if walking else Vector2.ZERO
	actor.move_blend = 1.0 if walking else 0.0
	actor.animate(0)
	actor.animation_clock = 0.0
	actor.animate(0)

func _sector(index: int) -> int:
	return direction_index if display_mode == 1 else index % 8

func _process(delta: float) -> void:
	if playing:
		for actor in actors:
			actor.animate(delta * playback_speed)
		_update_captions()

func _physics_process(delta: float) -> void:
	if not playing:
		return
	if walking and travel_preview:
		travel_clock += delta * playback_speed
	_update_travel(delta)

func _layout_actors() -> void:
	if not is_instance_valid(stage) or actors.is_empty():
		return
	var columns := 1 if display_mode == 1 else 8 if display_mode == 2 else 4
	var rows := 1 if display_mode == 1 else 2
	var cell := stage.size / Vector2(columns, rows)
	var max_scale := 4.5 if display_mode == 1 else 1.7 if display_mode == 2 else 2.5
	if travel_preview:
		max_scale = 2.4 if display_mode == 1 else 0.8
	# Reserve space for the complete selection ring below the soles as well as labels.
	var actor_scale := minf(max_scale, minf((cell.y - 60) / 76.0, (cell.x - 20) / 70.0))
	actor_scale = maxf(0.5, actor_scale)
	for i in range(actors.size()):
		var start := Vector2(i % columns, floori(float(i) / columns)) * cell
		actors[i].scale = Vector2.ONE * actor_scale
		stage_origins[i] = start + Vector2(cell.x * 0.5, (cell.y+32*actor_scale)*0.5 if travel_preview else 36+54*actor_scale)
		stage_anchors[i].position = stage_origins[i]
		direction_labels[i].position = start + Vector2(0, 4)
		direction_labels[i].size = Vector2(cell.x, 32)
		captions[i].position = start + Vector2(0, cell.y - 18)
		captions[i].size = Vector2(cell.x, 16)
	stage.queue_redraw()

func _update_travel(delta: float) -> void:
	var columns := 1 if display_mode == 1 else 8 if display_mode == 2 else 4
	var rows := 1 if display_mode == 1 else 2
	var cell := stage.size/Vector2(columns,rows)
	var route := Vector2(minf(cell.x*0.26,130),minf(cell.y*0.15,45))
	var progress := sin(travel_clock * TAU / 8.0)
	for i in range(actors.size()):
		var direction: Vector2 = DIRECTIONS[_sector(i)].sign()
		var target: Vector2 = direction * route * progress if travel_preview else Vector2.ZERO
		var actor := actors[i]
		var animation_motion: Vector2 = actor.motion
		var animation_moving: bool = actor.moving
		actor.move_with_velocity((stage_anchors[i].to_global(target) - actor.global_position) / delta)
		actor.motion = animation_motion
		actor.moving = animation_moving
	stage.queue_redraw()

func _draw_stage() -> void:
	# A fixed ground reference makes hovering, sliding and changes in scale easy to see.
	if travel_preview:
		for x in range(0,ceili(stage.size.x),32):
			stage.draw_line(Vector2(x,0),Vector2(x,stage.size.y),Color("172328"),1)
		for y in range(0,ceili(stage.size.y),32):
			stage.draw_line(Vector2(0,y),Vector2(stage.size.x,y),Color("172328"),1)
	for i in range(actors.size()):
		var actor := actors[i]
		var ground: Vector2 = stage_origins[i] + Vector2(0, 5 * actor.scale.y)
		stage.draw_line(ground - Vector2(36 * actor.scale.x, 0), ground + Vector2(36 * actor.scale.x, 0), Color("283839"), 1.0)
		stage.draw_line(ground - Vector2(0, 4), ground + Vector2(0, 4), Color("405652"), 1.0)

func _update_captions() -> void:
	for i in range(actors.size()):
		var sprite: AnimatedSprite2D = actors[i].sprite
		var label := "QUADRO"
		captions[i].text = (label+" %02d / %02d") % [sprite.frame + 1, sprite.sprite_frames.get_frame_count(sprite.animation)] if walking else "PARADA"

func toggle_playback() -> void:
	playing = not playing
	pause_button.text = "PAUSAR" if playing else "CONTINUAR"

func step_frame() -> void:
	if playing:
		toggle_playback()
	if not walking:
		return
	for actor in actors:
		var sprite: AnimatedSprite2D = actor.sprite
		var fps := sprite.sprite_frames.get_animation_speed(sprite.animation)
		actor.animation_clock = (sprite.frame + 1.01) / fps
		actor.animate(0)
	_update_captions()

func toggle_pose() -> void:
	walking = not walking
	pose_button.text = "VER PARADA" if walking else "VER CAMINHADA"
	restart_cycle()

func restart_cycle() -> void:
	travel_clock = 0.0
	for i in range(actors.size()):
		restart_actor(actors[i], i)
	_update_captions()

func toggle_travel() -> void:
	travel_preview = not travel_preview
	travel_button.text = "NO LUGAR" if travel_preview else "DESLOCAR"
	travel_clock = 0.0
	_layout_actors()

func set_weapon(weapon: String) -> void:
	selected_weapon = weapon
	for actor in actors:
		actor.weapon = weapon
		actor.weapon_pivot.visible = not weapon.is_empty()
		actor.gripping_hand.visible = not weapon.is_empty()
		actor.animate(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		match event.keycode:
			KEY_SPACE:
				toggle_playback()
			KEY_RIGHT:
				step_frame()
			KEY_R:
				restart_cycle()
			_:
				return
		get_viewport().set_input_as_handled()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_stylebox_override("normal", Pixel.panel(Color("211b2b"), Color("665069")))
	button.add_theme_stylebox_override("hover", Pixel.panel(Color("332335"), MINT))
	button.add_theme_stylebox_override("pressed", Pixel.panel(Color("3b2d39"), MINT))
	# Leave keyboard shortcuts with the viewer after clicking a playback control.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button
