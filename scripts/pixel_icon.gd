extends Control
## Authored tiny masks, scaled only by whole pixels.
var icon := "damage"
var accent := Color("efb775")
var large_weapon := false
static var weapon_textures: Dictionary = {}

# Larger authored weapon silhouettes for the selection screen. The small masks
# below remain unchanged for upgrade cards and HUD symbols.
const WEAPON_MASKS := {
	"return_blade": [
		"................................",
		"..................ooooo.........",
		"...............oooshhhho........",
		".............ooshhhhhho.........",
		"...........ooshhhhhoo...........",
		"..........oshhhhho..............",
		".........oshhhho......oooo......",
		"........oshhhho.....ooshho......",
		".......oshhhho....ooshhho.......",
		".......oshhho....oshhhho........",
		"......oshhho....oshhhho.........",
		"......oshhho...oshhhho..........",
		"......oaaaao..oshhhho...........",
		".......oaaaoooshhhho............",
		".......obbaahhhhho..............",
		".......obbraaaaoo...............",
		".......obbboooo.................",
		"........obbo....................",
		".........oo.....................",
		"................................",
	],
	"grenade_launcher": [
		"..................................",
		"..................................",
		"...............oooooooooooooooo...",
		".............oosshhhhhhhhhhhhhsso..",
		"...........oosssccccccccccccccsso..",
		".........oosgssssssssssssssssooo...",
		"....ooooosssgaaaaaaaaaaaaaaaso.o...",
		"...obbbbosssgsssssssssssssssso.o...",
		"..obrrrboossgssssssssssssssssooo...",
		"..obrrrbo..oooossssssssssssso......",
		"...obbbo....oobboooooooooooo......",
		"....obbo...obrbbo.................",
		"....obbo...obrbbo.................",
		"....obbo....obbo..................",
		".....oo......oo...................",
		"..................................",
	],
	"dual_pistols": [
		"..................................",
		"..................................",
		".......ooooooooooooooooooo........",
		".....ooshhhhhhhhhhhhhhhhso........",
		"....ooscccccccccccccccccso........",
		"...oosssaaaaasssssssssssso........",
		"...ossssssssssssssssssooo.........",
		"...obbbbooooossssooooo...........",
		"..obrrbbo...ooooo................",
		"..obrrbo..........................",
		"..obbbo...........................",
		"...ooo............................",
		"...........ooooooooooooooooooo....",
		".........ooshhhhhhhhhhhhhhhhso....",
		"........ooscccccccccccccccccso....",
		".......oosssaaaaasssssssssssso....",
		".......ossssssssssssssssssooo.....",
		".......obbbbooooossssooooo........",
		"......obrrbbo...ooooo.............",
		"......obrrbo......................",
		"......obbbo.......................",
		".......ooo........................",
	],
	"grenade_projectile": [
		"................",
		".......oooo.....",
		"......osssso....",
		"......ossooo....",
		".....oaaaaao....",
		"....oahhaaao....",
		"....oahhaaaao...",
		"....oaaaaaaao...",
		".....oaaaaao....",
		"......ooooo.....",
		"................",
		"................",
	],
	"revolver": [
		"................................",
		"................................",
		".............oo...........oo....",
		"....oo......ossooooooooooosso...",
		"...ossooooooshhhhhhhhhhhhhhso...",
		"...ossgsssssscccccccccccccsso...",
		"...ossssssssssassssssssssssso...",
		"...osgssooooosassooooooooooo....",
		"....ossohshsoosso...............",
		"....obsoshsssooo................",
		"...obbbosssso...................",
		"...obrbboooo....................",
		"..obrrbbo.......................",
		"..obrbbo........................",
		"..obbbbo........................",
		"...oooo.........................",
		"................................",
		"................................",
	],
	"shotgun": [
		"................................",
		"................................",
		"............................oo..",
		"..............oooooooooooooosso.",
		"..........ooooshhhhhhhhhhhhhso.",
		"........oossssscccccccccccccso.",
		"......oosgssssssssssssssssssso.",
		"....oobbbboooobbbbbbbbbbooooo...",
		"...obrrrrboooobrrrrrrrrbo.......",
		"..obrrrbboossoooooooooo.........",
		".obrrrbbo.oo....................",
		".obrrbbo........................",
		"..obbbbo........................",
		"...oooo.........................",
		"................................",
		"................................",
		"................................",
		"................................",
	],
	"wand": [
		"........................",
		".................oo.....",
		"................oaao....",
		"...............oahhao...",
		"..............oahhhhao..",
		"..............oahhhhao..",
		"...............oahhao...",
		"..............ooaaao....",
		".............osoooo.....",
		"............osso........",
		"...........obsso........",
		"..........obrbo.........",
		".........obrbo..........",
		"........obrbo...........",
		".......obsso............",
		"......osso..............",
		".....obrbo..............",
		"....obrbo...............",
		"...obrbo................",
		"..osso..................",
		"..oso...................",
		"...o....................",
		"........................",
		"........................",
	],
}

const MASKS := {
	"revolver": ["................", "................", "..oooooooooooo..", ".ossssssssssso..", ".ohhhhhhhhhhoo..", "..oooossoooo....", "....obsso.......", "....obbo........", "...obbbo........", "...obbbo........", "...oooo.........", "................"],
	"shotgun": ["................", "................", ".......oooooooo.", ".....oossssssso.", "...oossssssssso.", "..obbbbooooooo..", ".obbbbo.........", ".obbbo..........", "..ooo...........", "................", "................", "................"],
	"wand": [".........aa.....", "........ahha....", "........ahha....", ".........aa.....", "........obo.....", ".......obo......", "......obo.......", ".....obo........", "....obo.........", "...obo..........", "..obo...........", "...o............"],
	"damage": ["......aa........", ".....ahha.......", ".....ahha.......", ".....ahha.......", ".....ahha.......", ".....ahha.......", ".....aaaa.......", "....aaaaaa......", "......bb........", "......bb........", ".....oooo.......", "................"],
	"attack": ["................", "....aa....aa....", ".....aa....aa...", "......aa....aa..", ".......aa....aa.", "......aa....aa..", ".....aa....aa...", "....aa....aa....", "................", "................", "................", "................"],
	"speed": ["................", "......hhh.......", ".....hhaa.......", ".....aaaa.......", "....aaaaa.......", "....aaaao.......", "....aaaao.......", "...aaaaao.......", "..aaaaaaao......", "..oooooooo......", "................", "................"],
	"projectile": ["................", "...aa....aa.....", "..ahha..ahha....", "..ahha..ahha....", "..ahha..ahha....", "..aaaa..aaaa....", "..aaaa..aaaa....", "..bbbb..bbbb....", "..oooo..oooo....", "................", "................", "................"],
	"pierce": ["................", "........a.......", "........aa......", "..aaaaaaaaa.....", "..ahhhhhhaaa....", "..aaaaaaaaa.....", "........aa......", "........a.......", "................", "................", "................", "................"],
	"vitality": ["................", "..aaa...aaa.....", ".ahaaa.ahaaa....", ".ahhaaaaaaaa....", ".ahhaaaaaaaa....", "..aaaaaaaaa.....", "...aaaaaaa......", "....aaaaa.......", ".....aaa........", "......a.........", "................", "................"],
	"magnet": ["................", "......hh........", ".....haah.......", "....haaaah......", "...haaaaaah.....", "..haaaaaaaah....", "...haaaaaah.....", "....haaaah......", ".....haah.......", "......hh........", "................", "................"],
	"ember": [".......a........", "......aa........", ".....aaa..a.....", "....aaaa.aa.....", "...aaaaaaa......", "..aaaaahaaa.....", "..aaaahhaaa.....", "..aaahhhhaa.....", "...aahhhhaa.....", "....ahhhaa......", ".....aaaa.......", "................"],
	"skull": ["................", "....hhhhhhh.....", "...hhhhhhhhh....", "..hhhhhhhhhhh...", "..hhoohhhoohh...", "..hhoohhhoohh...", "...hhhhohhhh....", "....hhhhhhh.....", "....h.h.h.h.....", "................", "................", "................"],
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

static func weapon_texture(id: String) -> Texture2D:
	if weapon_textures.has(id):
		return weapon_textures[id]
	var mask: Array = WEAPON_MASKS[id]
	var width := 0
	for line in mask:
		width = maxi(width, line.length())
	var image := Image.create(width, mask.size(), false, Image.FORMAT_RGBA8)
	var accent: Color = {"wand": Color("83c9b3"), "return_blade": Color("b9a4e8"), "grenade_launcher": Color("eea477"), "grenade_projectile": Color("eea477")}.get(id, Color("efb775"))
	var palette := {"o": Color("100d18"), "s": Color("a397a8"), "h": Color("f2dfbd"), "c": Color("d1c5cf"), "g": Color("64566e"), "b": Color("72516a"), "r": Color("a16a70"), "a": accent}
	for y in range(mask.size()):
		for x in range(mask[y].length()):
			var key: String = mask[y][x]
			if palette.has(key):
				image.set_pixel(x, y, palette[key])
	var texture := ImageTexture.create_from_image(image)
	weapon_textures[id] = texture
	return texture

func _draw() -> void:
	var mask: Array = WEAPON_MASKS.get(icon, MASKS.damage) if large_weapon else MASKS.get(icon, MASKS.damage)
	var width := 0
	for line in mask:
		width = maxi(width, line.length())
	var dimensions := Vector2(width, mask.size())
	var step := maxf(1, floorf(minf(size.x / dimensions.x, size.y / dimensions.y)))
	var origin := ((size - dimensions * step) / 2).floor()
	var palette := {"o": Color("100d18"), "s": Color("a397a8"), "h": Color("f2dfbd"), "c": Color("d1c5cf"), "g": Color("64566e"), "b": Color("72516a"), "r": Color("a16a70"), "a": accent}
	for y in range(mask.size()):
		for x in range(mask[y].length()):
			var key: String = mask[y][x]
			if palette.has(key):
				draw_rect(Rect2(origin + Vector2(x, y) * step, Vector2.ONE * step), palette[key])
