extends Node
signal destination_changed
const CELL := 2.0
const ORIGIN := Vector2(-246,-232)
var game: Node3D
var grid := AStarGrid2D.new()
var destination := Vector3.ZERO
var destination_name := ""
var route := PackedVector2Array()
var distance := 0.0
var route_available := false
var automatic := true
var timer := 0.0
var pois: Array = []
var discovered: Array = []

func _ready() -> void:
	grid.region = Rect2i(0,0,225,137)
	grid.cell_size = Vector2.ONE*CELL
	grid.offset = ORIGIN
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for c in game.data.colliders:
		var center := Vector2.ZERO
		var half := Vector2.ZERO
		if c.get("c",false):
			center = Vector2(c.x,c.z)
			half = Vector2.ONE*(c.r+0.55)
		elif c.get("obb",false):
			center = Vector2(c.cx,c.cz)
			half = Vector2.ONE*(maxf(c.hx,c.hz)+0.55)
		else:
			center = Vector2((c.x0+c.x1)/2,(c.z0+c.z1)/2)
			half = Vector2((c.x1-c.x0)/2,(c.z1-c.z0)/2)+Vector2.ONE*0.55
		if center.x > 230:
			continue
		var lo := cell(center-half)-Vector2i.ONE
		var hi := cell(center+half)+Vector2i.ONE
		for x in range(maxi(0,lo.x),mini(225,hi.x+1)):
			for y in range(maxi(0,lo.y),mini(137,hi.y+1)):
				var p: Vector2 = grid.get_point_position(Vector2i(x,y))-center
				var blocked := false
				if c.get("c",false):
					blocked = p.length() < half.x
				elif c.get("obb",false):
					p = p.rotated(-atan2(c.sn,c.cs))
					blocked = absf(p.x)<c.hx+0.55 and absf(p.y)<c.hz+0.55
				else:
					blocked = absf(p.x)<half.x and absf(p.y)<half.y
				if blocked:
					grid.set_point_solid(Vector2i(x,y))
	pois = [{"name":"政大校門","pos":Vector3(-2,0,18),"kind":"place"},{"name":"四維堂","pos":Vector3(0,0,-72),"kind":"place"},{"name":"中央圖書館","pos":Vector3(-46,0,-78),"kind":"place"},{"name":"噴水池","pos":Vector3(0,0,-24),"kind":"place"},{"name":"田徑場","pos":Vector3(80,0,-126),"kind":"place"},{"name":"醉夢溪畔","pos":Vector3(-45,0,-158),"kind":"place"}]
	for lot in game.data.lots:
		pois.append({"name":lot.name,"pos":Vector3(lot.x,0,lot.z+lot.d/2+2),"kind":"place"})
	for i in range(game.data.stories.size()):
		var a: Array = game.data.stories[i].position
		pois.append({"name":game.data.stories[i].name,"pos":Vector3(a[0],0,a[2]),"kind":"story","index":i})
	for i in range(6):
		pois.append({"name":game.data.npcs[i].title,"pos":game.npcs[i].node.position,"kind":"person","index":i})
	# The story at Zuimeng Creek sits on its bridge; avoid routing through water.
	for x in range(grid.region.size.x):
		for y in range(grid.region.size.y):
			var id := Vector2i(x,y)
			var p: Vector2 = grid.get_point_position(id)
			if p.y>-115:
				continue
			var bridge := p-Vector2(-45,-158)
			if absf(bridge.dot(Vector2(0.973,-0.233)))<2.0 and absf(bridge.dot(Vector2(0.233,0.973)))<7.0:
				grid.set_point_solid(id,false)
				continue
			for i in range(1,game.data.river.size()):
				var a: Array = game.data.river[i-1]
				var b: Array = game.data.river[i]
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(a[0],a[1]),Vector2(b[0],b[1])))<3.6:
					grid.set_point_solid(id)
					break
	auto_destination()

func cell(p: Vector2) -> Vector2i:
	return Vector2i(((p-ORIGIN)/CELL).round())

func nearest_open(p: Vector2) -> Vector2i:
	var at := cell(p).clamp(Vector2i.ZERO,grid.region.end-Vector2i.ONE)
	if not grid.is_point_solid(at):
		return at
	for radius in range(1,18):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				if abs(x)!=radius and abs(y)!=radius:
					continue
				var next := at+Vector2i(x,y)
				if grid.is_in_boundsv(next) and not grid.is_point_solid(next):
					return next
	return at

func select_destination(pos: Vector3,title: String,auto: bool = false) -> void:
	destination = pos
	destination_name = title
	automatic = auto
	recalculate()
	destination_changed.emit()

func auto_destination() -> void:
	for i in range(game.data.stories.size()):
		if not i in game.collected:
			var p: Array = game.data.stories[i].position
			select_destination(Vector3(p[0],0,p[2]),game.data.stories[i].name,true)
			return
	if not game.completed:
		select_destination(Vector3(300,0,-12.5),"回四維堂向校長回報",true)
	else:
		destination_name = ""
		route.clear()

func recalculate() -> void:
	route.clear()
	distance = 0
	route_available = false
	if destination_name.is_empty():
		return
	var p: Vector3 = game.player.position
	var end := destination
	if p.x>250:
		if end.x<250:
			end = Vector3(300,0,22)
		route = PackedVector2Array([Vector2(p.x,p.z),Vector2(300,p.z),Vector2(300,end.z),Vector2(end.x,end.z)])
	else:
		if end.x>250:
			end = Vector3(0,0,-72)
		route = grid.get_point_path(nearest_open(Vector2(p.x,p.z)),nearest_open(Vector2(end.x,end.z)))
	route_available = route.size()>1
	for i in range(1,route.size()):
		distance += route[i-1].distance_to(route[i])

func _process(delta: float) -> void:
	timer += delta
	if timer<1.0:
		return
	timer = 0
	recalculate()
	for poi in pois:
		if poi.kind=="place" and not poi.name in discovered and game.player.position.distance_to(poi.pos)<13:
			discovered.append(poi.name)
			if is_instance_valid(game.hud):
				game.hud.toast("發現地點  ·  "+poi.name)
