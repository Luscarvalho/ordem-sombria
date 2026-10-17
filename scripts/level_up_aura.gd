extends Node2D
## A brief presentation beat: grounded rings and rising pixel sparks, no body jump.
const Pixel = preload("res://scripts/pixel_theme.gd")
const DURATION := 0.55
var elapsed := 0.0
var active := false
var level := 2

func _ready() -> void:
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hide()

func start(new_level: int) -> void:
	level = new_level
	elapsed = 0.0
	active = true
	show()
	queue_redraw()

func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(DURATION, elapsed + delta)
	if elapsed >= DURATION:
		cancel()
	else:
		queue_redraw()

func cancel() -> void:
	active = false
	hide()
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var t := elapsed / DURATION
	var fade := minf(1.0, (1.0 - t) * 4.0)
	var pulse := sin(PI * t)
	var mint := Color("83e4c8")
	var amber := Color("ffdc91")
	mint.a = fade
	amber.a = fade
	# Ground-plane ellipses anchor the effect at the boots.
	for layer in range(2):
		var radius := 15.0 + t * 18.0 + layer * 5.0
		var points := PackedVector2Array()
		for i in range(17):
			var angle := i * TAU / 16.0
			points.append((Vector2(cos(angle) * radius, 5.0 + sin(angle) * radius * 0.30)).round())
		var color := mint if layer == 0 else amber
		color.a *= 0.85 if layer == 0 else 0.45
		draw_polyline(points, color, 2.0)
	# Light rises beside the silhouette, leaving the character readable.
	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (12.0 + (i % 3) * 6.0 + pulse * 3.0)
		var y := 5.0 - fposmod(t * 64.0 + i * 11.0, 68.0)
		var p := Vector2(x, y).round()
		var color := mint if i % 3 else amber
		draw_rect(Rect2(p, Vector2(2, 5 if i % 3 else 2)), color)
		if i % 4 == 0:
			draw_rect(Rect2(p + Vector2(-2, 1), Vector2(6, 2)), color)
	if pulse > 0.25:
		var glow := mint
		glow.a *= pulse * 0.28
		var halo := PackedVector2Array()
		for i in range(17):
			var angle := i * TAU / 16.0
			halo.append(Vector2(cos(angle) * (18.0 + pulse * 5.0), -24.0 + sin(angle) * 30.0).round())
		draw_polyline(halo, glow, 1.0)
	var caption := "NÍVEL %d" % level
	var font := Pixel.font()
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var at := Vector2(-width * 0.5, -62.0 - t * 9.0).round()
	draw_string(font, at + Vector2(1, 1), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.06, 0.05, 0.1, fade))
	draw_string(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, amber)
