extends RefCounted
## Per-frame hand sockets. The unified atlas stores sockets on each frame resource;
## the original tables remain available for preserved earlier sheets.

const HANDS := {
	&"walk": [Vector2(338, 282), Vector2(772, 276), Vector2(1208, 276), Vector2(1659, 271), Vector2(331, 701), Vector2(770, 702), Vector2(1208, 700), Vector2(1659, 690)],
	&"walk_down": [Vector2(258, 231), Vector2(597, 237), Vector2(962, 222), Vector2(1341, 232), Vector2(1681, 236), Vector2(2044, 230)],
	&"walk_up_diagonal": [Vector2(383, 271), Vector2(877, 272), Vector2(1389, 272), Vector2(384, 749), Vector2(879, 751), Vector2(1389, 751)],
	&"walk_down_diagonal": [Vector2(277, 559), Vector2(634, 557), Vector2(1000, 558), Vector2(1360, 563), Vector2(1719, 557), Vector2(2084, 556)],
}
const IDLE_FRAME := {&"walk": 2, &"walk_down": 1, &"walk_up_diagonal": 1, &"walk_down_diagonal": 1}
# Each texture rotates around its handle, including the diagonal staff drawing.
const WEAPONS := {
	"revolver": {"grip": Vector2(5, 12), "muzzle": Vector2(30, 5), "scale": 0.65, "rotation": 0.0},
	"shotgun": {"grip": Vector2(7, 10), "muzzle": Vector2(31, 5), "scale": 0.85, "rotation": 0.0},
	"wand": {"grip": Vector2(5, 17), "muzzle": Vector2(18, 4), "scale": 0.95, "rotation": PI / 4.0},
}

static func source_hand(body: AnimatedSprite2D) -> Vector2:
	var texture := body.sprite_frames.get_frame_texture(body.animation, body.frame) as AtlasTexture
	if texture.has_meta("hand_socket"):
		return texture.get_meta("hand_socket")
	var cycle := StringName(str(body.animation).replace("idle", "walk"))
	if cycle == &"walk_up":
		# The back view's hand is hidden under the cloak; the weapon stays behind it.
		# Use the aligned canvas, so changing cloak silhouettes cannot move the wrist.
		return texture.region.position - texture.margin.position + texture.get_size() * Vector2(0.92, 0.59)
	var frame: int = body.frame if str(body.animation).begins_with("walk") else IDLE_FRAME[cycle]
	return HANDS[cycle][frame]

static func hand_position(body: AnimatedSprite2D) -> Vector2:
	var texture := body.sprite_frames.get_frame_texture(body.animation, body.frame) as AtlasTexture
	var local := source_hand(body) - texture.region.position + texture.margin.position - texture.get_size() * 0.5
	if body.flip_h:
		local.x = -local.x
	return body.transform * local
