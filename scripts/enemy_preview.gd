extends Control

const Pixel = preload("res://scripts/pixel_theme.gd")
const SCENES: Array[PackedScene] = [
	preload("res://scenes/characters/hunter.tscn"),
	preload("res://scenes/characters/enemies/spider.tscn"),
	preload("res://scenes/characters/enemies/runner.tscn"),
	preload("res://scenes/characters/enemies/armored_spider.tscn"),
	preload("res://scenes/characters/enemies/eye.tscn"),
	preload("res://scenes/characters/enemies/beast.tscn"),
	preload("res://scenes/characters/enemies/spitter.tscn"),
	preload("res://scenes/characters/enemies/colossus.tscn"),
	preload("res://scenes/characters/enemies/matriarch.tscn"),
]
const NAMES: Array[String] = ["CAÇADORA", "ARANHA", "ARANHA VELOZ", "ARANHA DE CARAPAÇA", "OLHO VIGIA", "FERA", "CUSPIDOR DE VENENO", "COLOSSO DAS CINZAS", "MATRIARCA DO ENXAME"]
const IDS: Array[String] = ["cacadora", "aranha", "aranha-veloz", "aranha-carapaca", "olho-vigia", "fera", "cuspidor", "colosso", "matriarca"]
const CARDINAL_DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const CARDINAL_NAMES: Array[String] = ["DIREITA", "BAIXO", "ESQUERDA", "CIMA"]
const HUNTER_DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1)]
const HUNTER_NAMES: Array[String] = ["DIREITA", "BAIXO/DIR", "BAIXO", "BAIXO/ESQ", "ESQUERDA", "CIMA/ESQ", "CIMA", "CIMA/DIR"]

@export_enum("Caçadora", "Aranha", "Aranha veloz", "Aranha de carapaça", "Olho vigia", "Fera", "Cuspidor", "Colosso", "Matriarca") var character_index := 1

var actors: Array[Node2D] = []
var panels: Array[Control] = []
var title: Label
var subtitle: Label
var selector: OptionButton
var playing := true

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = Pixel.theme()
	var background := ColorRect.new()
	background.color = Color("10171b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	title = _label("", 18, Color("f0dfbf"))
	title.position = Vector2(20, 13)
	add_child(title)
	subtitle = _label("", 10, Color("ac9ba9"))
	subtitle.position = Vector2(20, 39)
	add_child(subtitle)
	selector = OptionButton.new()
	selector.position = Vector2(20, 63)
	selector.custom_minimum_size = Vector2(230, 26)
	selector.focus_mode = Control.FOCUS_NONE
	for character_name in NAMES:
		selector.add_item(character_name)
	selector.item_selected.connect(show_character)
	add_child(selector)
	resized.connect(_layout)
	show_character(character_index)

func show_character(index: int) -> void:
	character_index = index
	for panel in panels:
		remove_child(panel)
		panel.queue_free()
	panels.clear()
	actors.clear()
	selector.select(index)
	title.text = NAMES[index]
	var directions := HUNTER_DIRECTIONS if index == 0 else CARDINAL_DIRECTIONS
	var direction_names := HUNTER_NAMES if index == 0 else CARDINAL_NAMES
	subtitle.text = "%d DIREÇÕES / RITMO DA PARTIDA / ESPAÇO: PAUSAR" % directions.size()
	for direction_index in range(directions.size()):
		var panel := Control.new()
		panel.name = "Direction%d" % direction_index
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.draw.connect(_draw_panel.bind(panel))
		add_child(panel)
		panels.append(panel)
		var label := _label(direction_names[direction_index], 11, Color("83c9b3"))
		label.name = "DirectionName"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(label)
		var anchor := Node2D.new()
		anchor.name = "Anchor"
		panel.add_child(anchor)
		var actor := SCENES[index].instantiate()
		actor.collision_layer = 0
		actor.collision_mask = 0
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		anchor.add_child(actor)
		actor.hurtbox.collision_layer = 0
		if actor.contact_hitbox != null:
			actor.contact_hitbox.monitoring = false
		actor.weapon = "revolver" if index == 0 else ""
		if index == 8:
			actor.brain = {"role": "boss", "boss": true, "archetype": "matriarch"}
		elif index == 3:
			actor.brain = {"role": "armored"}
		actor.reset_motion()
		actor.phase = 0.0
		actor.motion = directions[direction_index].normalized() * actor.speed
		actor.moving = true
		actor.aiming = index == 0
		actor.aim = directions[direction_index].normalized()
		actor.body_angle = actor.aim.angle()
		actor.visual_angle = actor.body_angle
		actor.move_blend = 1.0
		actor.animate(0.0)
		actors.append(actor)
	_layout()

func _layout() -> void:
	if panels.is_empty():
		return
	var columns := 4 if character_index == 0 else 2
	var cell := Vector2((size.x - 40) / columns, (size.y - 110) / 2.0)
	for index in range(panels.size()):
		var panel := panels[index]
		panel.position = Vector2(20, 104) + Vector2(index % columns, index / columns) * cell
		panel.size = cell - Vector2(8, 8)
		var label: Label = panel.get_node("DirectionName")
		label.position = Vector2(0, 10)
		label.size = Vector2(panel.size.x, 20)
		var anchor: Node2D = panel.get_node("Anchor")
		var actor := actors[index]
		var display_height := minf(116.0, cell.y - 58.0)
		var lower_extent: float = 24.0 if actor.kind == 0 else 6.0 + actor.radius * 0.37
		var scale_limit: float = (panel.size.y - 44.0) / (actor._height() - 6.0 + lower_extent)
		var width_limit: float = (panel.size.x - 30) / (actor.sprite.sprite_frames.get_frame_texture("idle", 0).get_width() * actor.base_scale)
		actor.scale = Vector2.ONE * minf(display_height / actor._height(), minf(scale_limit, width_limit))
		anchor.position = Vector2(panel.size.x * 0.5, panel.size.y - 8.0 - lower_extent * actor.scale.y)
		panel.queue_redraw()

func _process(delta: float) -> void:
	if playing:
		advance(delta)

func advance(delta: float) -> void:
	for actor in actors:
		actor.animate(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		playing = not playing
		get_viewport().set_input_as_handled()

func _draw_panel(panel: Control) -> void:
	panel.draw_style_box(Pixel.panel(Color("172023"), Color("344638")), Rect2(Vector2.ZERO, panel.size))
	var anchor: Node2D = panel.get_node("Anchor")
	var actor: Node2D = anchor.get_child(0)
	var ground := anchor.position + Vector2(0, 6.0 * actor.scale.y)
	panel.draw_line(ground - Vector2(52, 0), ground + Vector2(52, 0), Color("344638"), 1.0)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
