extends Node2D
## Deterministic world obstacles. Visuals share actor Y sorting; geometry exists offscreen too.
const CELL := 240.0
const MAX_RADIUS := 27.0
const SPAWN_CLEARANCE := 220.0
const ART_SIZE := Vector2i(40,48)
const ART_ANCHOR := Vector2(20,40)
var visual_parent: Node2D
var visible_cells := {}
var collision_cells := {}
var records := {}
var textures := {}
var focus_cell := Vector2i(999999,999999)

func setup(parent: Node2D) -> void:
	visual_parent = parent
	follow(Vector2.ZERO)

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x/CELL),floori(point.y/CELL))

func obstacle_at(cell: Vector2i) -> Dictionary:
	if records.has(cell):
		return records[cell]
	var random := RandomNumberGenerator.new()
	random.seed = (cell.x*73856093) ^ (cell.y*19349663) ^ 813337
	var data := {}
	if random.randf()<0.76:
		var point := (Vector2(cell)+Vector2.ONE*0.5)*CELL+Vector2(random.randf_range(-56,56),random.randf_range(-56,56))
		var kind := random.randi_range(0,2)
		var radius := [25.0,19.0,18.0][kind] as float
		if point.length()>SPAWN_CLEARANCE+radius:
			data={"cell":cell,"position":point.round(),"radius":radius,"kind":kind,"variant":random.randi_range(0,3)}
	records[cell]=data
	return data

func follow(point: Vector2) -> void:
	var center := cell_at(point)
	if center==focus_cell or not is_instance_valid(visual_parent):
		return
	focus_cell=center
	var required := {}
	for x in range(center.x-5,center.x+6):
		for y in range(center.y-4,center.y+5):
			var cell := Vector2i(x,y)
			var data := obstacle_at(cell)
			if data.is_empty(): continue
			required[cell]=true
			if visible_cells.has(cell): continue
			var body := _ensure_body(data)
			var sprite := Sprite2D.new()
			sprite.name="Sprite2D"
			sprite.texture=_texture(data.kind,data.variant)
			sprite.centered=false
			sprite.offset=-ART_ANCHOR
			sprite.scale=Vector2.ONE*2
			sprite.flip_h=data.variant%2==1
			# Keep the flipped image centered on the same footprint.
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			body.add_child(sprite)
			visible_cells[cell]=body
	for cell in visible_cells.keys():
		if not required.has(cell):
			var body: StaticBody2D=visible_cells[cell]
			var sprite: Sprite2D=body.get_node("Sprite2D")
			body.remove_child(sprite)
			sprite.queue_free()
			visible_cells.erase(cell)
	# Bound the query cache while retaining enemy/spawn neighborhoods around the camera.
	for cell in records.keys():
		if absi(cell.x-center.x)>12 or absi(cell.y-center.y)>12:
			records.erase(cell)
	for cell in collision_cells.keys():
		if absi(cell.x-center.x)>12 or absi(cell.y-center.y)>12:
			var body: StaticBody2D = collision_cells[cell]
			visual_parent.remove_child(body)
			body.queue_free()
			collision_cells.erase(cell)

func _ensure_body(data: Dictionary) -> StaticBody2D:
	if collision_cells.has(data.cell):
		return collision_cells[data.cell]
	var body := StaticBody2D.new()
	body.name = "TerrainObstacle_%d_%d" % [data.cell.x, data.cell.y]
	body.collision_layer = 4
	body.collision_mask = 0
	body.position = data.position
	var shape := CapsuleShape2D.new()
	shape.radius = data.radius
	shape.height = data.radius * 2.0
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.shape = shape
	body.add_child(collider)
	visual_parent.add_child(body)
	collision_cells[data.cell] = body
	return body

func ensure_collision(from: Vector2, to: Vector2, radius: float) -> void:
	for data in nearby(from, to, radius):
		_ensure_body(data)

func nearby(from: Vector2,to: Vector2,radius: float) -> Array[Dictionary]:
	var low := cell_at(from.min(to)-Vector2.ONE*(radius+MAX_RADIUS))
	var high := cell_at(from.max(to)+Vector2.ONE*(radius+MAX_RADIUS))
	var result: Array[Dictionary]=[]
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			var data := obstacle_at(Vector2i(x,y))
			if not data.is_empty(): result.append(data)
	return result

func safe_position(point: Vector2,radius: float) -> Vector2:
	var result := point
	for iteration in range(4):
		var corrected := false
		for data in nearby(result,result,radius):
			var offset: Vector2=result-data.position
			var minimum: float=radius+data.radius+0.05
			if offset.length_squared()<minimum*minimum:
				result=data.position+(offset.normalized() if offset.length_squared()>0.0001 else Vector2.RIGHT)*minimum
				corrected=true
		if not corrected: break
	return result

func cast(from: Vector2,displacement: Vector2,radius: float=0.0) -> Dictionary:
	var result := {"fraction":1.0,"normal":Vector2.ZERO,"obstacle":{}}
	var length_squared := displacement.length_squared()
	if length_squared<0.000001: return result
	for data in nearby(from,from+displacement,radius):
		var offset: Vector2=from-data.position
		var combined: float=radius+data.radius
		var b := offset.dot(displacement)
		var c := offset.length_squared()-combined*combined
		if c<=0.0:
			var normal := offset.normalized() if offset.length_squared()>0.0001 else -displacement.normalized()
			if b<0.0 or radius==0.0:
				return {"fraction":0.0,"normal":normal,"obstacle":data}
			continue
		var discriminant := b*b-length_squared*c
		if b>=0.0 or discriminant<0.0: continue
		var fraction := (-b-sqrt(discriminant))/length_squared
		if fraction>=0.0 and fraction<float(result.fraction):
			var normal := (from+displacement*fraction-Vector2(data.position)).normalized()
			result={"fraction":fraction,"normal":normal,"obstacle":data}
	return result

func steer(enemy: Node2D,desired: Vector2) -> Vector2:
	if desired.length_squared()<0.01: return desired
	var direction := desired.normalized()
	var hit := cast(enemy.position,direction*(65.0+enemy.radius),enemy.radius+8.0)
	if hit.obstacle.is_empty(): return desired
	var data: Dictionary=hit.obstacle
	var normal: Vector2=(enemy.position-data.position).normalized()
	if normal.length_squared()<0.01: normal=-direction
	if enemy.brain.get("avoid_cell",Vector2i(999999,999999))!=data.cell:
		var side := 1.0 if normal.orthogonal().dot(direction)>=0.0 else -1.0
		enemy.brain.avoid_cell=data.cell
		enemy.brain.avoid_side=side
	var tangent := normal.orthogonal()*float(enemy.brain.avoid_side)
	return (tangent+normal*0.25+direction*0.25).normalized()*desired.length()

func projectile_fraction(from: Vector2,to: Vector2) -> float:
	# Combat points are at torso height; map them back onto the same world footprint.
	return cast(from+Vector2(0,15),to-from).fraction

func clear_shot(from: Vector2,to: Vector2) -> bool:
	return projectile_fraction(from,to)>=1.0

func _texture(kind: int,variant: int) -> ImageTexture:
	var key := kind*4+variant
	if textures.has(key): return textures[key]
	var image := Image.create(ART_SIZE.x,ART_SIZE.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_ellipse(image,Vector2(20,40),Vector2(17,5),Color(0,0,0,0.3))
	var outline := Color("11151a")
	if kind==0:
		_polygon(image,[Vector2(3,35),Vector2(2,28),Vector2(7,21),Vector2(14,16),Vector2(26,17),Vector2(35,27),Vector2(37,36),Vector2(31,41),Vector2(8,41)],outline)
		_polygon(image,[Vector2(5,34),Vector2(5,28),Vector2(10,22),Vector2(16,19),Vector2(25,20),Vector2(32,28),Vector2(34,36),Vector2(29,38),Vector2(9,38)],Color("414952"))
		_polygon(image,[Vector2(7,28),Vector2(15,20),Vector2(24,21),Vector2(27,29),Vector2(19,32),Vector2(10,32)],Color("59616a"))
		_polygon(image,[Vector2(20,32),Vector2(28,28),Vector2(34,35),Vector2(29,38),Vector2(12,38)],Color("303842"))
		image.fill_rect(Rect2i(14,22,8,2),Color("71767a"))
		image.fill_rect(Rect2i(10,34,6,3),Color("3f5748"))
		image.fill_rect(Rect2i(8,36,6,2),Color("304238"))
	elif kind==1:
		_polygon(image,[Vector2(7,39),Vector2(9,29),Vector2(8,23),Vector2(15,19),Vector2(26,20),Vector2(31,25),Vector2(30,34),Vector2(35,41),Vector2(26,42),Vector2(20,39),Vector2(12,42),Vector2(4,41)],outline)
		_polygon(image,[Vector2(10,26),Vector2(28,26),Vector2(28,35),Vector2(32,39),Vector2(26,39),Vector2(22,36),Vector2(20,38),Vector2(13,39),Vector2(8,39)],Color("554035"))
		image.fill_rect(Rect2i(12,27,4,10),Color("735443"))
		image.fill_rect(Rect2i(22,28,3,8),Color("382e2d"))
		_ellipse(image,Vector2(19,25),Vector2(11,6),Color("241e23"))
		_ellipse(image,Vector2(19,24),Vector2(9,4),Color("9a7952"))
		_ellipse(image,Vector2(19,24),Vector2(6,3),Color("624936"))
		_ellipse(image,Vector2(19,24),Vector2(3,1),Color("a48257"))
		image.fill_rect(Rect2i(27,36,4,3),Color("41513c"))
	else:
		_polygon(image,[Vector2(10,40),Vector2(9,35),Vector2(13,33),Vector2(13,17),Vector2(17,12),Vector2(21,16),Vector2(25,13),Vector2(28,17),Vector2(28,33),Vector2(32,36),Vector2(31,41)],outline)
		_polygon(image,[Vector2(15,18),Vector2(18,16),Vector2(21,19),Vector2(25,16),Vector2(26,19),Vector2(26,35),Vector2(15,35)],Color("52515b"))
		image.fill_rect(Rect2i(16,20,3,14),Color("747078"))
		image.fill_rect(Rect2i(23,20,3,15),Color("383b46"))
		image.fill_rect(Rect2i(12,36,17,3),Color("64616b"))
		image.fill_rect(Rect2i(14,39,15,1),Color("333944"))
		image.fill_rect(Rect2i(19,27,4,2),Color("29323a"))
		image.fill_rect(Rect2i(20,25,2,6),Color("29323a"))
		image.fill_rect(Rect2i(24,34,4,3),Color("405748"))
	# Restrained chips and moss distinguish repeated props without extra image files.
	var random := RandomNumberGenerator.new()
	random.seed=key*1777+91
	for i in range(4):
		var p := Vector2i(random.randi_range(10,28),random.randi_range(25,37))
		if image.get_pixelv(p).a>0.9:
			image.fill_rect(Rect2i(p,Vector2i(2,1)),Color("49584b"))
	var texture := ImageTexture.create_from_image(image)
	textures[key]=texture
	return texture

func _polygon(image: Image,points: PackedVector2Array,color: Color) -> void:
	for y in range(ART_SIZE.y):
		for x in range(ART_SIZE.x):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),points): image.set_pixel(x,y,color)

func _ellipse(image: Image,center: Vector2,radius: Vector2,color: Color) -> void:
	for y in range(maxi(0,int(center.y-radius.y)),mini(ART_SIZE.y,int(center.y+radius.y+1))):
		for x in range(maxi(0,int(center.x-radius.x)),mini(ART_SIZE.x,int(center.x+radius.x+1))):
			if ((Vector2(x,y)-center)/radius).length_squared()<=1.0: image.set_pixel(x,y,color)
