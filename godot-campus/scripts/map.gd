extends Control
var game: Node3D
var expanded := false

func project_point(p: Vector3) -> Vector2:
	return Vector2((p.x + 245.0) / 440.0, (p.z + 230.0) / 260.0) * size

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	draw_style_box(get_theme_stylebox("panel", "Panel"), Rect2(Vector2.ZERO, size))
	var river := PackedVector2Array()
	for p in game.data.river:
		river.append(project_point(Vector3(p[0], 0, p[1])))
	draw_polyline(river, Color("477985"), 5.0, true)
	draw_line(project_point(Vector3(0, 0, 20)), project_point(Vector3(0, 0, -80)), Color("657078"), 5.0)
	for lot in game.data.lots:
		var a := project_point(Vector3(lot.x - lot.w / 2, 0, lot.z - lot.d / 2))
		var b := project_point(Vector3(lot.x + lot.w / 2, 0, lot.z + lot.d / 2))
		draw_rect(Rect2(a, b - a), Color("404b50"))
	for p in [Vector3(-23, 0, -32), Vector3(23, 0, -32), Vector3(0, 0, -86)]:
		draw_rect(Rect2(project_point(p) - Vector2(6, 8), Vector2(12, 16)), Color("6e756d"))
	for i in range(game.data.stories.size()):
		if i in game.collected:
			continue
		var a = game.data.stories[i].position
		var pos := Vector3(a[0], 0, a[2])
		if pos.x > 250:
			pos = Vector3(0, 0, -75)
		draw_circle(project_point(pos), 4, Color("edc879"))
	var p: Vector3 = game.player.position
	if p.x > 250:
		p = Vector3(0, 0, -75)
	var center := project_point(p)
	var heading: float = game.player.yaw
	var arrow := PackedVector2Array()
	for v in [Vector2(0, -7), Vector2(-4, 5), Vector2(0, 3), Vector2(4, 5)]:
		arrow.append(center + v.rotated(-heading))
	draw_colored_polygon(arrow, Color("fff4d9"))
	draw_string(get_theme_default_font(), Vector2(10, 20), "N ↑  政大校園", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c4cfca"))
