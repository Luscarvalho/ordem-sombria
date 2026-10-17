extends Node2D
## Two-bone gait for the down diagonals. Texture pieces retain the original PNG pixels;
## foot trajectories, support changes and knee bends are animated by the scene.
const SOURCE_FRAMES = preload("res://assets/animations/hunter-directions-v6.tres")
const STRIDE := 55.0
const LIFT := 27.0
const FLOOR_Y := 445.0
const HIPS := [Vector2(258,315),Vector2(304,315)]
const KNEES := [Vector2(229,353),Vector2(327,356)]
const ANKLES := [Vector2(215,413),Vector2(339,414)]
const SOLES := [Vector2(221,445),Vector2(345,445)]
const THIGHS := [
	[Vector2(239,303),Vector2(281,313),Vector2(247,365),Vector2(213,352)],
	[Vector2(281,302),Vector2(322,302),Vector2(350,352),Vector2(305,370)],
]
const BOOTS := [
	[Vector2(213,340),Vector2(252,353),Vector2(231,406),Vector2(231,419),Vector2(173,419),Vector2(174,405),Vector2(197,366)],
	[Vector2(297,342),Vector2(343,340),Vector2(354,394),Vector2(368,419),Vector2(308,419),Vector2(307,385)],
]
const FEET := [
	[Vector2(179,402),Vector2(229,402),Vector2(232,413),Vector2(253,423),Vector2(251,445),Vector2(190,445),Vector2(168,429)],
	[Vector2(309,402),Vector2(361,402),Vector2(369,414),Vector2(394,414),Vector2(405,426),Vector2(399,445),Vector2(309,445)],
]
var active := false
var body_texture: AtlasTexture
var body: AnimatedSprite2D
var origin := Vector2.ZERO
var thighs: Array[Node2D] = []
var boots: Array[Node2D] = []
var foot_nodes: Array[Node2D] = []
var upper_body: Node2D
var feet: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var supported: Array[bool] = [true,true]
var phase := 0.0

func setup(sprite: AnimatedSprite2D) -> void:
	body = sprite
	body_texture = SOURCE_FRAMES.get_frame_texture("idle_down_diagonal",0) as AtlasTexture
	origin = body_texture.region.position-body_texture.margin.position+body_texture.get_size()*0.5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in range(2):
		var thigh := Node2D.new()
		add_child(thigh)
		_piece(thigh,THIGHS[i],HIPS[i])
		thighs.append(thigh)
		var boot := Node2D.new()
		add_child(boot)
		_piece(boot,BOOTS[i],KNEES[i])
		boots.append(boot)
		var foot_node := Node2D.new()
		add_child(foot_node)
		_piece(foot_node,FEET[i],ANKLES[i])
		foot_nodes.append(foot_node)
	# Fixed upper body, lower cape and belt flap cover the limb joints.
	upper_body = Node2D.new()
	add_child(upper_body)
	_piece(upper_body,[Vector2(65,40),Vector2(410,40),Vector2(410,316),Vector2(65,316)],origin)
	_piece(upper_body,[Vector2(65,314),Vector2(222,314),Vector2(213,340),Vector2(187,362),Vector2(165,354),Vector2(148,364),Vector2(120,351),Vector2(96,353),Vector2(65,330)],origin)
	_piece(upper_body,[Vector2(259,309),Vector2(285,309),Vector2(269,337),Vector2(248,344)],origin)
	hide()

func _piece(parent: Node2D, points: Array, pivot: Vector2) -> void:
	var polygon := Polygon2D.new()
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point: Vector2 in points:
		vertices.append(point-pivot)
		uv.append(point)
	polygon.polygon = vertices
	polygon.uv = uv
	polygon.texture = body_texture.atlas
	polygon.antialiased = false
	parent.add_child(polygon)

func update_pose(enabled: bool, clock: float, period: float, walking: bool) -> void:
	active = enabled
	visible = enabled
	if not enabled:
		return
	position = body.position
	scale = body.scale*Vector2(-1 if body.flip_h else 1,1)
	modulate = body.modulate
	phase = fposmod(clock/period,1.0)
	# Rise slightly over the supporting leg without scaling the artwork or lifting its foot.
	upper_body.position.y = -pow(sin(TAU*phase),2)*3.0 if walking else 0.0
	for leg in range(2):
		var p := fposmod(phase+(0.5 if leg==0 else 0.0),1.0)
		var x := 0.0
		var lift := 0.0
		supported[leg] = not walking or p<=0.5
		if walking:
			if p<=0.5:
				# The planted foot travels backwards relative to the moving body.
				x = lerpf(STRIDE,-STRIDE,p*2.0)
			else:
				# The other foot passes the hip and lands in front; half a cycle apart.
				var swing := (p-0.5)*2.0
				x = lerpf(-STRIDE,STRIDE,swing)
				lift = sin(PI*swing)*LIFT
		var hip: Vector2 = HIPS[leg]+upper_body.position
		var foot := Vector2(hip.x+6.0+x,FLOOR_Y-lift)
		feet[leg] = foot-origin
		# Keep the sole flat while planted; flex the foot slightly only during swing.
		var foot_rotation := -0.12*sin(PI*(p-0.5)*2.0) if walking and p>0.5 else 0.0
		var ankle: Vector2 = foot-(SOLES[leg]-ANKLES[leg]).rotated(foot_rotation)
		var upper: float = HIPS[leg].distance_to(KNEES[leg])
		var lower: float = KNEES[leg].distance_to(ANKLES[leg])
		var delta: Vector2 = ankle-hip
		# A small extension at the ends of the stride keeps the two contact poses
		# distinct even with the original short, stylized legs.
		var stretch := maxf(1.0,delta.length()/(upper+lower-0.01))
		upper *= stretch
		lower *= stretch
		var distance := clampf(delta.length(),absf(upper-lower)+0.01,upper+lower-0.01)
		var axis: Vector2 = delta.normalized()
		var along := (upper*upper-lower*lower+distance*distance)/(2.0*distance)
		var bend := sqrt(maxf(0.0,upper*upper-along*along))
		var knee: Vector2 = hip+axis*along+Vector2(axis.y,-axis.x)*bend
		thighs[leg].position = hip-origin
		thighs[leg].scale = Vector2.ONE*stretch
		thighs[leg].rotation = (knee-hip).angle()-(KNEES[leg]-HIPS[leg]).angle()
		boots[leg].position = knee-origin
		boots[leg].scale = Vector2.ONE*stretch
		boots[leg].rotation = (ankle-knee).angle()-(ANKLES[leg]-KNEES[leg]).angle()
		foot_nodes[leg].position = ankle-origin
		foot_nodes[leg].rotation = foot_rotation

func _process(_delta: float) -> void:
	# External invincibility/flash tint changes are copied without advancing the gait.
	if active:
		modulate = body.modulate

func hand_position() -> Vector2:
	var socket: Vector2 = body_texture.get_meta("hand_socket")
	return transform*(socket-origin+upper_body.position)

func foot_position(leg: int) -> Vector2:
	return transform*feet[leg]
