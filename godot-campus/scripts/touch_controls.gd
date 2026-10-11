extends Control
## Track touch IDs independently so movement, camera and actions work simultaneously.
var game: Node3D
var move_id := -1
var look_id := -1
var action_ids: Dictionary = {}
var origin := Vector2.ZERO
var stick := Vector2.ZERO
var buttons: Dictionary = {}
var radius := 62.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func layout(dimensions: Vector2) -> void:
	size = dimensions
	origin = Vector2(100,size.y-112)
	buttons = {"interact":Vector2(size.x-82,size.y-108),"jump":Vector2(size.x-82,size.y-220),"sprint":Vector2(size.x-195,size.y-100)}
	queue_redraw()

func reset() -> void:
	move_id = -1
	look_id = -1
	action_ids.clear()
	stick = Vector2.ZERO
	game.player.touch_move = Vector2.ZERO
	game.player.touch_sprint = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible or not game.player.enabled:
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index==move_id:
				move_id = -1
				stick = Vector2.ZERO
				game.player.touch_move = Vector2.ZERO
			if event.index==look_id:
				look_id = -1
			if action_ids.get(event.index,"")=="sprint":
				game.player.touch_sprint = false
			action_ids.erase(event.index)
		elif event.position.distance_to(origin)<radius*1.7 and move_id==-1:
			move_id = event.index
			move_stick(event.position)
		else:
			for action in buttons:
				if event.position.distance_to(buttons[action])<46:
					action_ids[event.index] = action
					if action=="interact":
						game.interact()
					elif action=="jump":
						game.player.touch_jump = true
					else:
						game.player.touch_sprint = true
					get_viewport().set_input_as_handled()
					queue_redraw()
					return
			if event.pressed and event.position.x>size.x*0.42 and look_id==-1:
				look_id = event.index
	if event is InputEventScreenDrag:
		if event.index==move_id:
			move_stick(event.position)
		elif event.index==look_id:
			game.player.yaw -= event.relative.x*0.005
			game.player.pitch = clampf(game.player.pitch-event.relative.y*0.005,-0.9,0.35)
	queue_redraw()

func move_stick(at: Vector2) -> void:
	stick = ((at-origin)/radius).limit_length()
	game.player.touch_move = stick

func _draw() -> void:
	draw_circle(origin,radius,Color(0.06,0.11,0.15,0.45))
	draw_arc(origin,radius,0,TAU,48,Color(0.9,0.94,0.9,0.32),2,true)
	draw_circle(origin+stick*radius,24,Color(0.88,0.93,0.9,0.65))
	for action in buttons:
		var p: Vector2 = buttons[action]
		var held: bool = action in action_ids.values()
		draw_circle(p,40,Color(0.52,0.38,0.73,0.7) if held else Color(0.04,0.08,0.12,0.58))
		draw_arc(p,40,0,TAU,40,Color(0.95,0.92,0.83,0.5),1.5,true)
		var caption: String = {"interact":"互動","jump":"跳躍","sprint":"跑步"}[action]
		if game.player.driving:
			caption = {"interact":"下車","jump":"煞車","sprint":"加速"}[action]
		draw_string(get_theme_default_font(),p+Vector2(-18,6),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f2ecd9"))
