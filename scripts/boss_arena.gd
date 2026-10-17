extends Node2D
## A fixed world-space arena; geometry and effects advance only with the run.
const RADIUS := 400.0
const WALL_SEGMENTS := 96
const WALL_THICKNESS := 16.0
var active := false
var age := 0.0
var boundary: StaticBody2D

func _ready() -> void:
	boundary = StaticBody2D.new()
	boundary.name = "Boundary"
	boundary.collision_layer = 0
	boundary.collision_mask = 0
	var half_angle := PI / WALL_SEGMENTS
	var wall_radius := RADIUS * cos(half_angle) + WALL_THICKNESS * 0.5
	for segment in range(WALL_SEGMENTS):
		var angle := (segment + 0.5) * TAU / WALL_SEGMENTS
		var shape := RectangleShape2D.new()
		shape.size = Vector2(2.0 * wall_radius * tan(half_angle) + 0.5, WALL_THICKNESS)
		var collider := CollisionShape2D.new()
		collider.name = "Wall%d" % segment
		collider.shape = shape
		collider.position = Vector2.from_angle(angle) * wall_radius
		collider.rotation = angle + PI * 0.5
		boundary.add_child(collider)
	add_child(boundary)
	hide()

func begin(center: Vector2) -> void:
	if active: return
	position=center.round()
	age=0.0
	active=true
	boundary.collision_layer = 8
	show()
	queue_redraw()

func release() -> void:
	active=false
	boundary.collision_layer = 0
	age=0.0
	hide()
	queue_redraw()

func advance(delta: float) -> void:
	if not active: return
	age+=delta
	queue_redraw()

func contains(point: Vector2,radius: float=0.0) -> bool:
	return point.distance_squared_to(position)<=pow(maxf(0,RADIUS-radius),2)

func fit_position(point: Vector2,radius: float,terrain: Node2D) -> Vector2:
	var limit:=RADIUS-radius-0.2
	var candidate:=position+(point-position).limit_length(limit)
	for iteration in range(8):
		candidate=terrain.safe_position(candidate,radius)
		if contains(candidate,radius+0.05): return candidate
		candidate=position+(candidate-position).limit_length(limit-iteration*3)
	# A prop crossing the rim must not pin a spawn between the two colliders.
	var direction:=(point-position).angle()
	for ring in range(4):
		for step in range(16):
			candidate=position+Vector2.from_angle(direction+step*TAU/16)*limit*(0.8-ring*0.2)
			var safe: Vector2=terrain.safe_position(candidate,radius)
			if contains(safe,radius+0.05): return safe
	return position

func _draw() -> void:
	if not active: return
	var rim:=PackedVector2Array()
	for i in range(65):
		var at:=Vector2.from_angle(i*TAU/64)
		rim.append((at*RADIUS/2).round()*2)
		if i<64:
			var next:=Vector2.from_angle((i+1)*TAU/64)
			draw_colored_polygon(PackedVector2Array([at*RADIUS,next*RADIUS,next*2400,at*2400]),Color(0.025,0.015,0.045,0.5))
	draw_polyline(rim,Color("100f19"),14)
	draw_polyline(rim,Color("4b2f52"),9)
	draw_polyline(rim,Color("956178"),3)
	var glow:=Color("e39cbb")
	glow.a=0.65+0.2*sin(age*3)
	for i in range(24):
		var p:=(Vector2.from_angle(i*TAU/24)*RADIUS/2).round()*2
		draw_rect(Rect2(p-Vector2(4,6),Vector2(8,12)),Color("201b2b"))
		draw_rect(Rect2(p-Vector2(1,5),Vector2(2,10)),glow)
		draw_rect(Rect2(p-Vector2(3,1),Vector2(6,2)),glow)
		var spark:=p+Vector2(0,-10-fposmod(age*12+i*3,14)).round()
		draw_rect(Rect2(spark,Vector2(2,4)),glow)
