extends SceneTree

const FAMILIES := {
	"crawler": 13.0,
	"eye": 8.0,
	"beast": 8.0,
	"colossus": 4.5,
	"spitter": 7.0,
}
const VIEWS: Array[String] = ["side", "down", "up"]
const FRAME_COUNT := 6

func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() == 2 and arguments[0] == "--inspect":
		var image := Image.load_from_file(arguments[1])
		print("IMAGE: %s, alpha %s, corner %s, center gutter %s" % [image.get_size(), image.detect_alpha(), image.get_pixel(0, 0), image.get_pixel(image.get_width() / 6, image.get_height() / 2)])
		quit()
		return
	for family in FAMILIES:
		_build_family(family, FAMILIES[family])
	quit()

func _build_family(family: String, fps: float) -> void:
	var path := "res://assets/animations/%s-directions-v1.png" % family
	var texture: Texture2D = load(path)
	assert(texture != null, "Missing directional sheet: " + path)
	var image := texture.get_image()
	assert(image.get_pixel(0, 0).a < 0.02, "Sprite sheet background must be transparent: " + path)
	var bounds: Array[Rect2i] = []
	var largest := Vector2i.ZERO
	var row_cuts := _find_cuts(image, true, 0, image.get_width(), VIEWS.size())
	for row in range(VIEWS.size()):
		var column_cuts := _find_cuts(image, false, row_cuts[row], row_cuts[row + 1], FRAME_COUNT)
		for column in range(FRAME_COUNT):
			var start := Vector2i(column_cuts[column], row_cuts[row])
			var end := Vector2i(column_cuts[column + 1], row_cuts[row + 1])
			var low := end
			var high := start
			for pixel_y in range(start.y, end.y):
				for pixel_x in range(start.x, end.x):
					if image.get_pixel(pixel_x, pixel_y).a > 0.5:
						low = low.min(Vector2i(pixel_x, pixel_y))
						high = high.max(Vector2i(pixel_x + 1, pixel_y + 1))
			assert(high.x > low.x and high.y > low.y, "Empty directional frame: %s %s %d" % [family, VIEWS[row], column])
			low = (low - Vector2i(2, 2)).max(start)
			high = (high + Vector2i(2, 2)).min(end)
			var region := Rect2i(low, high - low)
			bounds.append(region)
			largest = largest.max(region.size)
	var canvas := largest + Vector2i(12, 12)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var report := {"source": path, "grid": [FRAME_COUNT, VIEWS.size()], "canvas": [canvas.x, canvas.y], "fps": fps, "directions": {}}
	for row in range(VIEWS.size()):
		var suffix := "" if row == 0 else "_" + VIEWS[row]
		var walk := "walk" + suffix
		var idle := "idle" + suffix
		frames.add_animation(walk)
		frames.set_animation_speed(walk, fps)
		frames.set_animation_loop(walk, true)
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 4.0)
		report.directions[VIEWS[row]] = []
		for column in range(FRAME_COUNT):
			var region := bounds[row * FRAME_COUNT + column]
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(region)
			atlas.margin = Rect2(Vector2(floorf((canvas.x - region.size.x) / 2.0), canvas.y - region.size.y - 6), Vector2(canvas - region.size))
			atlas.filter_clip = true
			frames.add_frame(walk, atlas)
			if column == 0:
				frames.add_frame(idle, atlas)
			report.directions[VIEWS[row]].append([region.position.x, region.position.y, region.size.x, region.size.y])
	assert(ResourceSaver.save(frames, "res://assets/animations/%s-directions-v1.tres" % family) == OK)
	var file := FileAccess.open("res://assets/animations/%s-directions-v1-frames.json" % family, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("BUILT: %s, canvas %s, rows %s" % [family, canvas, row_cuts])

func _find_cuts(image: Image, horizontal: bool, cross_start: int, cross_end: int, parts: int) -> Array[int]:
	var length := image.get_height() if horizontal else image.get_width()
	var search_radius := length / (parts * 3)
	var cuts: Array[int] = [0]
	for part in range(1, parts):
		var nominal := part * length / parts
		var best := nominal
		var best_score := INF
		for coordinate in range(nominal - search_radius, nominal + search_radius + 1):
			var occupied := 0
			for cross in range(cross_start, cross_end):
				var pixel := Vector2i(cross, coordinate) if horizontal else Vector2i(coordinate, cross)
				if image.get_pixelv(pixel).a > 0.5:
					occupied += 1
			var score := occupied + absf(coordinate - nominal) * 0.001
			if score < best_score:
				best = coordinate
				best_score = score
		cuts.append(best)
	cuts.append(length)
	return cuts
