extends Control
## Dedicated pixel sprites for ranked cards, extending the native icon style.
var buff := "damage"
var accent := Color("efb775")

const MASKS := {
	"reload": [
		"................", ".....aaaaa......", "...aahhhhhhaa...", "..aah.....haa...",
		".aah.......haa..", ".aa.........aaa.", ".aa.......aaaaa.", "..........aaaaa.",
		".aaaaa..........", ".aaaaa.......aa.", ".aaa.........aa.", "..aah.......haa.",
		"...aah.....haa..", "...aahhhhhhaa...", ".....aaaaa......", "................"],
	"ammo": [
		"................", "...oo...oo......", "..ohho.ohho.....", "..oaao.oaao.....",
		"..oaao.oaao.....", "..obbo.obbo.....", "..obbo.obbo.....", "..obbo.obbo.....",
		"..osso.osso.....", "..oooo.oooo.....", "...bbbbbbbbbb...", "...baabaabbb....",
		"...baabaabbb....", "...bbbbbbbbb....", "....ooooooo.....", "................"],
	"damage": [
		"................", "......oooo......", "......osso......", "......oddo......",
		".....obbbbo.....", "....obbbbbbo....", "...obbaaabbbo...", "...obbahabbbo...",
		"...obbaaaabbo...", "...obbbabbbbo...", "...obbababbo....", "...obbbbbbbbo...",
		"...obbbbbbbbo...", "....oooooooo....", "................", "................"],
	"attack": [
		"................", "........oo......", "......oohhoo....", "....oohahahao...",
		"...ohahahahao...", "...ohahahahao...", "...oaaaaaaao....", "..ooaaaaaaao....",
		"..ohhaaaaaao....", "...oaaaaaao.....", "....oaaaao......", "....osssso......",
		"....obbbbbo.....", "....obbbbbo.....", ".....ooooo......", "................"],
	"speed": [
		"................", ".......oooo.....", "......ohaao.....", "......ohaao.....",
		"......oaaao.....", "......oaaao.....", "..hh..oaaao.....", ".aa...oaaao.....",
		"......oaaao.....", "..aa..oaaaooo...", ".aa..oaaaaaaao..", ".....oahaaaaao..",
		"....oaaaaaaaao..", "....osssssssso..", ".....oooooooo...", "................"],
	"projectile": [
		"................", "...oo......oo...", "..ohho....ohho..", "..ohaao...ohaao.",
		"..oaaao...oaaao.", "..oaaao...oaaao.", "..osssso..osssso", "..obbbbo..obbbbo",
		"..obbbbo..obbbbo", "..obbbbo..obbbbo", "..obbbbo..obbbbo", "..osssso..osssso",
		"..oooooo..oooooo", "................", "................", "................"],
	"pierce": [
		"................", ".........oo.....", ".......ooaao....", "......oabbao....",
		".....oab.bao....", "....oab..bao....", ".ooooooo.bao....", "ohhhhhhaaoao....",
		".ooooooo.bao....", "....oab..bao....", ".....oab.bao....", "......oabbao....",
		".......ooaao....", ".........oo.....", "................", "................"],
	"vitality": [
		"................", "...ooo...ooo....", "..ohhho.ohhho...", ".ohahhaoahaaao..",
		".ohhaaaaaaaaao..", ".oahaaaaaaaado..", ".oaaaaaaaadddo..", "..oaaaaaadddo...",
		"..oaaaaaddddo...", "...oaaaddddo....", "....oaadddo.....", ".....oaddo......",
		"......ooo.......", ".......o........", "................", "................"],
	"magnet": [
		"................", ".......oo.......", "......ohho......", ".....ohaaho.....",
		"....ohaaaaho....", "...ohaaaaaaho...", "...ohaaooaaho...", "..ohaao..oaaho..",
		"..oaaaaooaaaao..", "...oaaaaaaaao...", "....oaaaaaao....", ".....oaaaao.....",
		"......oaao......", ".......oo.......", "...hh......hh...", "................"],
	"ember": [
		"................", "........o.......", ".......oao......", "......ohao......",
		"......ohaoo.....", ".....ohaaoao....", "...oohaaaaao....", "...oaaaaaaaoo...",
		"..oaaaahaaaao...", "..oaaahhhaado...", "..oaahhhhaado...", "..oaahhhaaado...",
		"...oaahhaado....", "....oaaaado.....", ".....ooooo......", "................"],
	"critical": [
		"................", ".......aa.......", ".......aa.......", ".....oooooo.....",
		"...oossssssoo...", "..osssaaasssso..", ".osssaahahassso.", "aosssahhhasssoa.",
		"aosssahhhasssoa.", ".osssaahahassso.", "..osssaaasssso..", "...oossssssoo...",
		".....oooooo.....", ".......aa.......", ".......aa.......", "................"],
	"ricochet": [
		"................", "..........oooo..", ".........ohhho..", "........ohaao...",
		".......ohaao....", "......ohaao.....", ".....ohaao......", ".....oaao.......",
		"......oaao......", ".......oaao.....", "..ooo...oaao....", "..ohho...oaao...",
		"..oahhooooaaao..", "..oaaaaaaaaaao..", "..oooooooooooo..", "................"],
	"finisher": [
		"................", ".......oo.......", "......ohho......", ".....ohhhho.....",
		".....ohaaao.....", ".....ohaaao.....", ".....oaaaao.....", ".....oaaaao.....",
		"...o.oaaaao.o...", "....oossssoo....", "....oobbbboo....", "...o.obbbbo.o...",
		".....osssso.....", ".....oooooo.....", "......aaaa......", "................"],
	"frost": [
		"................", ".......hh.......", "...h...aa...h...", "...ah..aa..ha...",
		"....ah.aa.ha....", ".....ahaaah.....", "......ahha......", ".hhaaaahhaaaahh.",
		".hhaaaahhaaaahh.", "......ahha......", ".....ahaaah.....", "....ah.aa.ha....",
		"...ah..aa..ha...", "...h...aa...h...", ".......hh.......", "................"],
	"poison": [
		"................", ".....oooooo.....", ".....obbbbo.....", ".....oooooo.....",
		"......osso......", ".....osssso.....", "....os....so....", "...os......so...",
		"...osaa.aaaso...", "...osahaaaaso...", "...osaaaaaaso...", "...osaaooaaso...",
		"...osaaaaaaso...", "....osssssso....", ".....oooooo.....", "................"],
	"explosion": [
		"................", "........ah......", ".......ah.......", "......oo........",
		".....obboo......", "....ooooooo.....", "...obbbbbbbbo...", "..obhhbbbbbbbo..",
		"..obhbbbbbbbbo..", "..obbbssssbbbo..", "..obbsossobsbo..", "..obbbssssbbbo..",
		"...obbbssbbbo...", "....obbbbbbo....", ".....oooooo.....", "................"],
	"lightning": [
		"................", "........oooo....", ".......ohhho....", "......ohhho.....",
		".....ohhho......", "....ohhho.......", "...ohhhhoooo....", "...oaaaaaaao....",
		"....ooooaao.....", ".......oaao.....", "......oaao......", ".....oaao.......",
		"....oaao........", "....oao.........", ".....o..........", "................"],
	"orbs": [
		"................", "......oooo......", ".....ohhaao.....", ".....ohaado.....",
		"......oooo......", "..oo........oo..", ".obbo......obbo.", "obbo..oooo..obbo",
		"obbo.ohhhao.obbo", ".obbohaaadoobbo.", "..oo.oaaado.oo..", "......oooo......",
		".....obbbbo.....", "......oooo......", "................", "................"],
	"shield": [
		"................", "..oooooooooooo..", "..ohhsssssaaao..", "..ohsaaaaaaado..",
		"..osaaaahaaado..", "..osaaahhhaado..", "..osaaaahaaado..", "..osaaaahaaado..",
		"...osaaaaaado...", "...osaaaaaado...", "....osaaaado....", ".....osaado.....",
		"......osdo......", ".......oo.......", "................", "................"],
	"vampire": [
		"................", "..oo........oo..", "..osooooooooso..", "..ossssssssso...",
		"..ossooooosso...", "..osso..oosso...", "...oso...oso....", "...oso...oso....",
		"....o.....o.....", ".......a........", "......aha.......", "......aaa.......",
		".....aaaaa......", ".....addda......", "......aaa.......", "................"],
	"revenge": [
		"................", ".......aa.......", "..a....aa....a..", "...a...aa...a...",
		"....a.oooo.a....", ".....ohhhao.....", "....ohahahao....", ".aaaohhhaaaoaaa.",
		".aaaoaaaaaaoaaa.", "....oaaaaaao....", ".....oaaaao.....", "....a.oooo.a....",
		"...a...aa...a...", "..a....aa....a..", ".......aa.......", "................"],
	"pact": [
		"................", "....oooooooo....", "...osssssssso...", "...oshhssssso...",
		"...osaaaaasso...", "...osaooaaaso...", "...osaoaoaaso...", "...osaaaoaaso...",
		"...osaaaaoaso...", "...osaoooaaso...", "...osaaaaasso...", "...osssssssso...",
		"...ossssaoooo...", "....oooaha......", ".......aaa......", "........a......."],
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func _draw() -> void:
	var mask: Array = MASKS.get(buff, [])
	var width := 16
	for line in mask:
		width = maxi(width, line.length())
	var step := maxf(1, floorf(minf(size.x / width, size.y / 16.0)))
	var origin := ((size - Vector2(width, 16) * step) * 0.5).floor()
	var palette := {"o": Color("100d18"), "a": accent, "h": accent.lightened(0.50), "d": accent.darkened(0.45), "s": Color("f0dfbf"), "b": Color("72516a")}
	for y in range(mask.size()):
		for x in range(mask[y].length()):
			var color: String = mask[y][x]
			if palette.has(color):
				draw_rect(Rect2(origin + Vector2(x, y) * step, Vector2.ONE * step), palette[color])
