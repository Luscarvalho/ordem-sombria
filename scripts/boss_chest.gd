extends Node2D
## Native pixel-art loot, sorted at its ground footprint like the actors.
const PICKUP_DELAY := 0.35
const PICKUP_RADIUS := 28.0
const OPEN_LIFETIME := 0.7
static var textures := {}
var age := 0.0
var opened := false

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func advance(delta: float) -> void:
	age+=delta
	queue_redraw()

func open() -> void:
	opened=true
	age=0.0
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(art(opened),Rect2(-28,-48,56,56),false)
	if not opened:
		var color:=Color("ffdc91")
		color.a=0.55+0.35*sin(age*4.0)
		for i in range(2):
			var p:=Vector2(-23 if i==0 else 22,-34 if i==0 else -26)
			draw_rect(Rect2(p-Vector2(1,3),Vector2(2,6)),color)
			draw_rect(Rect2(p-Vector2(3,1),Vector2(6,2)),color)

static func art(is_open: bool=false) -> ImageTexture:
	if textures.has(is_open): return textures[is_open]
	var image:=Image.create(28,28,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(21,27):
		for x in range(2,27):
			if ((Vector2(x,y)-Vector2(14,24))/Vector2(12,3)).length_squared()<=1.0:
				image.set_pixel(x,y,Color(0,0,0,0.35))
	var outline:=Color("17121e")
	var gold:=Color("c78a46")
	var light:=Color("ffdc91")
	image.fill_rect(Rect2i(3,12,22,12),outline)
	image.fill_rect(Rect2i(5,14,18,8),Color("714337"))
	image.fill_rect(Rect2i(6,15,16,2),Color("986044"))
	image.fill_rect(Rect2i(5,20,18,2),Color("493035"))
	image.fill_rect(Rect2i(4,22,20,1),gold)
	for x in [7,19]:
		image.fill_rect(Rect2i(x,13,2,10),gold)
		image.fill_rect(Rect2i(x,14,1,7),light)
	if is_open:
		image.fill_rect(Rect2i(5,2,18,10),outline)
		image.fill_rect(Rect2i(6,3,16,7),gold)
		image.fill_rect(Rect2i(8,4,12,5),Color("624135"))
		image.fill_rect(Rect2i(6,3,16,1),light)
		image.fill_rect(Rect2i(5,12,18,4),Color("2c202b"))
		for x in [8,12,17,20]: image.fill_rect(Rect2i(x,13,2,2),light)
	else:
		image.fill_rect(Rect2i(6,7,16,2),outline)
		image.fill_rect(Rect2i(4,9,20,5),outline)
		image.fill_rect(Rect2i(6,9,16,3),Color("a26b48"))
		image.fill_rect(Rect2i(5,11,18,2),Color("84523e"))
		for x in [7,19]:
			image.fill_rect(Rect2i(x,9,2,5),gold)
			image.fill_rect(Rect2i(x,9,1,4),light)
		image.fill_rect(Rect2i(5,13,18,1),gold)
		image.fill_rect(Rect2i(11,13,6,7),outline)
		image.fill_rect(Rect2i(12,14,4,5),light)
		image.fill_rect(Rect2i(13,16,2,2),Color("61403b"))
	var texture:=ImageTexture.create_from_image(image)
	textures[is_open]=texture
	return texture
