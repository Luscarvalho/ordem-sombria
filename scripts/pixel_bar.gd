extends Control
## Segmented meter with an integer-pixel fill and a recessed frame.
var max_value := 100.0:
	set(amount):
		max_value = maxf(1.0, amount)
		queue_redraw()
var value := 100.0:
	set(amount):
		value = amount
		queue_redraw()
var color := Color("d98486")
var segments := 20
var flat := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y <= 0:
		custom_minimum_size.y = 1 if flat else 14
	resized.connect(queue_redraw)

func _draw() -> void:
	if flat:
		draw_rect(Rect2(Vector2.ZERO, size), Color("32293e"))
		var width := floorf(size.x * clampf(value / max_value, 0.0, 1.0))
		if width > 0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(width, size.y)), color)
		return
	if size.y <= 8:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0e0c16"))
		var fill := clampf(value / max_value, 0, 1)
		for i in range(segments):
			var start := floorf(i * size.x / segments)
			var end := floorf((i + 1) * size.x / segments) - 1
			var rect := Rect2(start, 1, maxf(1, end-start), maxf(1, size.y-2))
			draw_rect(rect, Color("32293e"))
			var amount := clampf(fill*size.x-start, 0, rect.size.x)
			if amount > 0:
				draw_rect(Rect2(rect.position, Vector2(amount, rect.size.y)), color)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("0e0c16"))
	draw_rect(Rect2(Vector2(0, size.y - 2), Vector2(size.x, 2)), Color("625067"))
	var width := size.x - 8
	var fill := clampf(value / max_value, 0, 1)
	for i in range(segments):
		var start := floorf(i * width / segments)
		var end := floorf((i + 1) * width / segments) - 2
		var rect := Rect2(4 + start, 3, end - start, size.y - 7)
		draw_rect(rect, Color("32293e"))
		var filled := floorf(clampf(fill * width - start, 0, end - start) / 2) * 2
		if filled > 0:
			draw_rect(Rect2(rect.position, Vector2(filled, rect.size.y)), color)
			draw_rect(Rect2(rect.position, Vector2(filled, 2)), color.lightened(0.23))
