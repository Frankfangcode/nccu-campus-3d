extends Control
signal selected(title: String)
var game: Node3D
var expanded := false
var zoom := 1.0
var center := Vector2(-20,-66)
var drag_start := Vector2.ZERO
var dragged := false
var filter := "all"
var label_rects: Array[Rect2] = []

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP if expanded else Control.MOUSE_FILTER_IGNORE

func scale_factor() -> float:
	return minf(size.x/450.0,size.y/330.0)*zoom if expanded else size.x/100.0

func map_center() -> Vector2:
	if game.player.position.x>250:
		return Vector2(300,0) if expanded else Vector2(game.player.position.x,game.player.position.z)
	return center if expanded else Vector2(game.player.position.x,game.player.position.z)

func project_point(p: Vector3) -> Vector2:
	return point(Vector2(p.x,p.z))

func point(p: Vector2) -> Vector2:
	return (p-map_center())*scale_factor()+size/2

func text_at(p: Vector2,caption: String,font_size: int = 13,color: Color = Color("a6b5ba")) -> void:
	var extent := get_theme_default_font().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	var bounds := Rect2(p-Vector2(2,font_size),extent+Vector2(4,4))
	for occupied in label_rects:
		if bounds.intersects(occupied):
			return
	label_rects.append(bounds)
	draw_string(get_theme_default_font(),p,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func line_world(points: Array,color: Color,width: float) -> void:
	var projected := PackedVector2Array()
	for p in points:
		projected.append(point(Vector2(p[0],p[1])))
	if projected.size()>1:
		draw_polyline(projected,color,width*scale_factor(),true)

func building(pos: Vector2,dimensions: Vector2,title: String = "") -> void:
	var rect := Rect2(point(pos-dimensions/2),dimensions*scale_factor())
	draw_rect(rect,Color("344249"))
	draw_rect(rect,Color("54616a"),false,1)
	if expanded and zoom>0.85 and not title.is_empty():
		text_at(rect.position+Vector2(3,-5),title,12)

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player) or not is_instance_valid(game.navigation):
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color("111d25"))
	label_rects.clear()
	for x in range(-260,230,20):
		draw_line(point(Vector2(x,-240)),point(Vector2(x,45)),Color(0.3,0.4,0.45,0.1),1)
	for z in range(-240,50,20):
		draw_line(point(Vector2(-260,z)),point(Vector2(230,z)),Color(0.3,0.4,0.45,0.1),1)
	if game.player.position.x>250:
		building(Vector2(300,0),Vector2(28,50),"四維堂・室內")
		building(Vector2(300,-21),Vector2(24,7),"舞台")
		line_world([[300,23],[300,-16]],Color("69756c"),3)
	else:
		line_world(game.data.river,Color("203f4b"),11)
		line_world(game.data.river,Color("315e6b"),6)
		for road in [[[-240,25],[195,25]],[[-80,-12.8],[0,-12.8],[96,-1.28],[170,7.6]],[[0,15],[0,-73]],[[-96,-77.48],[66,-48.32]],[[96,0.7],[96,-40.62]],[[-77,7],[-77,-123]],[[-35,-130],[44,-150]]]:
			line_world(road,Color("263943"),5.5)
			line_world(road,Color("587078"),1.3)
		for road in [[[-77,-57],[-232,-57]],[[-79,-25],[-79,-133]],[[-144,-57],[-144,-98]],[[-144,-98],[-228,-87]],[[-228,-57],[-228,-119]],[[-191,-88],[-193,-97]]]:
			line_world(road,Color("587078"),5.5)
		for lot in game.data.lots:
			if lot.name in ["教育學院","李園","鳳凰林"]:
				continue
			building(Vector2(lot.x,lot.z),Vector2(lot.w,lot.d),"" if lot.get("map_only",false) else lot.name)
		line_world([[-150,42],[149,42]],Color("587078"),8.0)
		draw_arc(point(Vector2(80,-126)),20*scale_factor(),0,TAU,64,Color("93564b"),5*scale_factor(),true)
		draw_circle(point(Vector2(0,-32)),5.8*scale_factor(),Color("315d67"))
		if expanded:
			text_at(point(Vector2(-90,34)),"指 南 路 二 段",14,Color("d2d4b9"))
			text_at(point(Vector2(-140,-157)),"醉 夢 溪",15,Color("6facbb"))
	var nav: Node = game.navigation
	if nav.route.size()>1:
		var projected := PackedVector2Array()
		for p in nav.route:
			projected.append(point(p))
		draw_polyline(projected,Color(0.64,0.42,0.99,0.18),9,true)
		draw_polyline(projected,Color("bd86ff"),3.5,true)
	for poi in nav.pois:
		if (poi.pos.x>250)!=(game.player.position.x>250):
			continue
		if filter!="all" and poi.kind!=filter:
			continue
		if poi.kind=="story" and poi.index in game.collected:
			continue
		var p := project_point(poi.pos)
		var color := Color("e9c66f") if poi.kind=="story" else (Color("76c8dc") if poi.kind=="person" else Color("829695"))
		if poi.kind=="place" and not expanded:
			continue
		draw_circle(p,7 if expanded else 5,Color("10171e"))
		draw_circle(p,4.5 if expanded else 3.2,color)
		if expanded and (poi.kind=="story" or zoom>1.6):
			var caption: String = poi.name
			if poi.kind=="story":
				caption = ["校名碑","醉夢溪","四維堂"][poi.index]
			text_at(p+Vector2(10,4),caption,12,color)
	if not nav.destination_name.is_empty() and (nav.destination.x>250)==(game.player.position.x>250):
		var destination_point := project_point(nav.destination)
		draw_arc(destination_point,11,0,TAU,32,Color("ce9eff"),2,true)
	if game.player.position.x<250:
		var c := project_point(game.car.position)
		draw_rect(Rect2(c-Vector2(5,3),Vector2(10,6)),Color("70baec"))
	var at := project_point(game.player.position)
	var arrow := PackedVector2Array()
	for v in [Vector2(0,-10),Vector2(-6,7),Vector2(0,4),Vector2(6,7)]:
		arrow.append(at+v.rotated(-game.player.yaw))
	draw_circle(at,13,Color(1,1,1,0.08))
	draw_colored_polygon(arrow,Color("f0f5e8"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("586a6d"),false,1)
	text_at(Vector2(12,22),"N ↑  "+("校園地圖" if expanded else "RADAR"),12,Color("d3dbd7"))
	if expanded:
		text_at(Vector2(16,size.y-16),"拖曳平移 · 點選地點導航 · 滾輪／＋－縮放",13)

func zoom_by(factor: float) -> void:
	zoom = clampf(zoom*factor,0.7,5.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not expanded:
		return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.18)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0/1.18)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = event.position
				dragged = false
			elif not dragged:
				choose(event.position)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if event.position.distance_to(drag_start)>8:
			dragged = true
		if dragged:
			center -= event.relative/scale_factor()
			queue_redraw()
	accept_event()

func choose(at: Vector2) -> void:
	var nearest: Dictionary = {}
	var limit := 30.0
	for poi in game.navigation.pois:
		if (poi.pos.x>250)!=(game.player.position.x>250) or (filter!="all" and poi.kind!=filter):
			continue
		var d := at.distance_to(project_point(poi.pos))
		if d<limit:
			limit = d
			nearest = poi
	var p: Vector2 = (at-size/2)/scale_factor()+map_center()
	var dest: Vector3 = nearest.pos if not nearest.is_empty() else Vector3(p.x,0,p.y)
	var title: String = nearest.name if not nearest.is_empty() else "自訂目的地"
	game.navigation.select_destination(dest,title)
	selected.emit(title)
	queue_redraw()
