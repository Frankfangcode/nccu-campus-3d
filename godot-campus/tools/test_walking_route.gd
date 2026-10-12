extends SceneTree
## Drive the real capsule along the returned paths, never teleport between stops.
var game: Node3D
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://scenes/campus.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://walking_route_test.json"
	game.visit_photo_route()
	for i in range(25):
		await physics_frame
	for destination_name in ["法學院","游泳館","實小附設幼兒園","莊敬九舍","井塘樓"]:
		var matches: Array = game.navigation.pois.filter(func(poi): return poi.name==destination_name)
		var target: Vector3 = matches[0].pos
		game.navigation.select_destination(target,destination_name)
		var route: PackedVector2Array = game.navigation.route.duplicate()
		var reached: bool = game.navigation.route_available
		for point in route:
			var ticks := 0
			while Vector2(game.player.position.x,game.player.position.z).distance_to(point)>0.35 and ticks<180:
				var direction: Vector2 = (point-Vector2(game.player.position.x,game.player.position.z)).normalized()
				game.player.yaw = 0
				game.player.touch_move = direction
				await physics_frame
				ticks += 1
			if ticks==180:
				reached = false
				printerr("WALK_STUCK ",destination_name," at ",game.player.position," toward ",point)
				break
		game.player.touch_move = Vector2.ZERO
		if not reached:
			failures += 1
			break
		print("WALK_PASS ",destination_name," final=",game.player.position)
	# The swimming-pool steps use a walkable collision ramp.
	game.player.position = Vector3(-132,0.2,-105)
	game.player.velocity = Vector3.ZERO
	for i in range(30):
		await physics_frame
	game.player.yaw = 0
	game.player.touch_move = Vector2(0,-1)
	for i in range(60):
		await physics_frame
	game.player.touch_move = Vector2.ZERO
	if game.player.position.y<0.35:
		failures += 1
		printerr("STAIR_FAIL ",game.player.position)
	else:
		print("STAIR_PASS pool entry ",game.player.position)
	print("WALKING_RESULT failures=",failures)
	quit(0 if failures==0 else 1)
