extends RefCounted

const PixelPanel = preload("res://scripts/pixel_panel.gd")
const SOURCE = preload("res://assets/fonts/Silkscreen-Regular.ttf")
static var cached_font: FontFile

static func font() -> FontFile:
	if cached_font == null:
		cached_font = SOURCE.duplicate() as FontFile
		cached_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		cached_font.hinting = TextServer.HINTING_NONE
		cached_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		cached_font.oversampling = 1.0
		cached_font.generate_mipmaps = false
	return cached_font

static func panel(background: Color, border: Color, bevel: bool = true) -> StyleBox:
	var box := PixelPanel.new()
	box.background = background
	box.border = border
	box.bevel = bevel
	box.set_content_margin_all(8)
	return box

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = 16
	result.set_stylebox("panel", "TooltipPanel", panel(Color("211b2b"), Color("70566e")))
	result.set_color("font_color", "TooltipLabel", Color("f0dfbf"))
	result.set_font_size("font_size", "TooltipLabel", 12)
	return result
