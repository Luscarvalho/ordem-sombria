extends StyleBox
## Stepped corners and a two-tone bevel, drawn on whole pixels without filtering.
var background := Color("211c2c")
var border := Color("68536c")
var pixel := 2.0
var bevel := true

func _draw(item: RID, rect: Rect2) -> void:
	var r := Rect2(rect.position.round(), rect.size.floor())
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var step := minf(pixel, minf(r.size.x, r.size.y) / 4.0)
	_shape(item, r, Color("0c0b13"), step * 2)
	var inner := r.grow(-step)
	_shape(item, inner, border, step)
	_shape(item, r.grow(-step * 2), background, step)
	if bevel and r.size.x > step * 8 and r.size.y > step * 8:
		RenderingServer.canvas_item_add_rect(item, Rect2(r.position + Vector2(step * 3, step * 2), Vector2(r.size.x - step * 6, step)), border.lightened(0.24))
		RenderingServer.canvas_item_add_rect(item, Rect2(r.position + Vector2(step * 3, r.size.y - step * 3), Vector2(r.size.x - step * 6, step)), border.darkened(0.4))

func _shape(item: RID, r: Rect2, color: Color, notch: float) -> void:
	if r.size.x <= 0 or r.size.y <= 0:
		return
	RenderingServer.canvas_item_add_rect(item, Rect2(r.position + Vector2(notch, 0), Vector2(maxf(0, r.size.x - notch * 2), r.size.y)), color)
	RenderingServer.canvas_item_add_rect(item, Rect2(r.position + Vector2(0, notch), Vector2(r.size.x, maxf(0, r.size.y - notch * 2))), color)
