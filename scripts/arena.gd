extends Node2D
## Cached pixel-art ground; decoration stays fixed in world space as the camera moves.
const CELL_SIZE := 96
const TILE_PIXELS := 48
const GROUND := Color("10171b")
const GRASS := [Color("1b2927"), Color("263830"), Color("344638")]
const STONE := [Color("151c22"), Color("30353d"), Color("45464d")]

var focus := Vector2.ZERO
var tile := Vector2i(99999, 99999)
var ground_atlas: ImageTexture
var spawn_texture: ImageTexture

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas := Image.create(TILE_PIXELS * 8, TILE_PIXELS * 4, false, Image.FORMAT_RGBA8)
	for variant in range(32):
		var at := Vector2i(variant % 8, floori(float(variant) / 8.0)) * TILE_PIXELS
		atlas.blit_rect(_make_ground_image(variant), Rect2i(0, 0, TILE_PIXELS, TILE_PIXELS), at)
	ground_atlas = ImageTexture.create_from_image(atlas)
	spawn_texture = _make_spawn_texture()

func follow(point: Vector2) -> void:
	focus = point
	var next_tile := Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))
	if next_tile != tile:
		tile = next_tile
		position = Vector2(tile) * CELL_SIZE
		queue_redraw()

func _draw() -> void:
	if ground_atlas == null:
		return
	draw_rect(Rect2(-2200, -1600, 4400, 3200), GROUND)
	for x in range(-22, 23):
		for y in range(-16, 17):
			var seed_value := (tile.x + x) * 73856093 ^ (tile.y + y) * 19349663
			var variant := posmod(seed_value, 32)
			var source := Vector2(variant % 8, floori(float(variant) / 8.0)) * TILE_PIXELS
			draw_texture_rect_region(ground_atlas, Rect2(Vector2(x, y) * CELL_SIZE, Vector2.ONE * CELL_SIZE), Rect2(source, Vector2.ONE * TILE_PIXELS))
	# The birthplace is attached to world zero, never to the moving terrain grid.
	var origin := -position
	if absf(origin.x) < 2400 and absf(origin.y) < 1800:
		draw_texture_rect(spawn_texture, Rect2(origin - Vector2(144, 144), Vector2(288, 288)), false)

func _make_ground_image(variant: int) -> Image:
	var image := Image.create(TILE_PIXELS, TILE_PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(GROUND)
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 7919 + 137
	# Small, broken patches avoid the old oversized checkerboard tiles.
	for i in range(5):
		var p := Vector2i(rng.randi_range(2, 35), rng.randi_range(2, 38))
		var width := rng.randi_range(5, 11)
		var height := rng.randi_range(3, 7)
		var color := Color("141e20") if i % 2 == 0 else Color("121b1e")
		image.fill_rect(Rect2i(p + Vector2i(2, 0), Vector2i(width - 3, 1)), color)
		image.fill_rect(Rect2i(p + Vector2i(0, 1), Vector2i(width, height - 2)), color)
		image.fill_rect(Rect2i(p + Vector2i(1, height - 1), Vector2i(width - 3, 1)), color)
	for i in range(7):
		var p := Vector2i(rng.randi_range(2, 41), rng.randi_range(2, 41))
		var blades: Array[String] = ["  1  ", "1 12 ", "1121 ", " 010 "]
		if i % 3 == 0:
			blades = ["   1 ", "  12 ", " 121 ", "010  "]
		_stamp(image, p, blades, GRASS)
	for i in range(12):
		var p := Vector2i(rng.randi_range(0, 46), rng.randi_range(0, 46))
		image.fill_rect(Rect2i(p, Vector2i(1 + i % 2, 1)), Color("1e2929"))
	if rng.randf() < 0.24:
		var p := Vector2i(rng.randi_range(4, 35), rng.randi_range(4, 37))
		_stamp(image, p, [" 0000 ", "012210", "011110", " 0000 "], STONE)
	return image

func _make_spawn_texture() -> ImageTexture:
	var image := Image.create(144, 144, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8317
	# Every edge is rasterized on the same two-world-unit grid as the grass.
	for y in range(144):
		for x in range(144):
			var offset := Vector2(x - 72, y - 72)
			var radius := offset.length()
			var angle := fposmod(offset.angle() + PI / 12.0, TAU)
			var sector := floori(angle / (TAU / 12.0))
			var seam := fposmod(angle, TAU / 12.0) * radius < 1.2
			if radius >= 64.0 and radius < 66.0:
				image.set_pixel(x, y, Color("0b1116"))
			elif radius >= 58.0 and radius < 64.0:
				var color := Color("393440") if sector % 3 else Color("403a47")
				if radius >= 63.0:
					color = Color("514654")
				elif radius < 59.0:
					color = Color("252630")
				elif radius < 60.0:
					color = Color("48404b")
				if seam:
					color = Color("1a2027")
				image.set_pixel(x, y, color)
			elif radius >= 55.0 and radius < 56.0:
				image.set_pixel(x, y, Color("2b3939"))
			elif radius < 55.0:
				# Worn flagstones, with staggered joints and occasional chipped pixels.
				var row := floori(float(y) / 12.0)
				var joint := posmod(x + (row % 2) * 10, 20) == 0 or y % 12 == 0
				var color := Color("151c22") if (floori(float(x + (row % 2) * 10) / 20.0) + row) % 3 else Color("182025")
				if joint:
					color = Color("11181d")
				elif rng.randf() < 0.035:
					color = Color("20292d")
				image.set_pixel(x, y, color)
	# Twelve small, angular engravings around the stone rim.
	var rune_colors := [Color("1c272b"), Color("5a7064"), Color("384d49")]
	var runes: Array = [
		[" 1 ", "111", " 1 ", " 1 ", " 2 "],
		["1 1", " 1 ", " 1 ", "1 1", "2 2"],
		["11 ", "  1", " 1 ", "1  ", "222"],
	]
	for i in range(12):
		var p := Vector2i((Vector2(72, 72) + Vector2.from_angle(i * TAU / 12.0) * 61.0).round())
		_stamp(image, p - Vector2i(1, 2), runes[i % runes.size()], rune_colors)
	# A subdued central sigil is visible again when the hunter leaves the spawn.
	for y in range(-16, 17):
		for x in range(-16, 17):
			var diamond := absi(x) + absi(y)
			if diamond == 15 or diamond == 16:
				image.set_pixel(72 + x, 72 + y, Color("344541"))
	_stamp(image, Vector2i(69, 66), ["   1   ", "  121  ", " 1 2 1 ", "1  2  1", " 1 2 1 ", "  121  ", "   1   ", "   2   ", "  222  "], [Color("182328"), Color("4c6258"), Color("2e423e")])
	return ImageTexture.create_from_image(image)

func _stamp(image: Image, at: Vector2i, rows: Array, palette: Array) -> void:
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var digit: String = rows[y][x]
			if digit == " ":
				continue
			var p := at + Vector2i(x, y)
			if p.x >= 0 and p.x < image.get_width() and p.y >= 0 and p.y < image.get_height():
				image.set_pixelv(p, palette[digit.to_int()])
