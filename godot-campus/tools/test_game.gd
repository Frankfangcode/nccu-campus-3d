extends SceneTree
var game: Node3D
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	print("PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	game = load("res://scenes/campus.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://campus_test_save.json"
	game.set_playing(true)
	await frames(40)
	check(game.player.is_on_floor(), "spawn has a solid ground")
	check(game.navigation.pois.size()>=30,"map contains landmarks, stories and characters")
	game.navigation.select_destination(Vector3(0,0,-72),"四維堂")
	check(game.navigation.route_available,"navigation finds a route to Siwei Hall")
	var safe := true
	for point in game.navigation.route:
		if game.navigation.grid.is_point_solid(game.navigation.cell(point)):
			safe = false
	check(safe,"navigation route does not cross building collision cells")
	game.hud.toggle_map()
	check(game.hud.map_large and not game.player.enabled,"map pauses character input")
	game.hud.atlas.choose(game.hud.atlas.project_point(Vector3(0,0,-72)))
	check(not game.navigation.automatic,"map click selects a manual destination")
	game.hud.toggle_map()
	check(game.player.enabled,"closing map restores movement")
	game.navigation.auto_destination()
	var start: Vector3 = game.player.position
	Input.action_press("forward")
	await frames(90)
	Input.action_release("forward")
	check(game.player.position.z < start.z - 3, "W moves the character forward through the gate")
	Input.action_press("jump")
	await frames(10)
	Input.action_release("jump")
	check(game.player.position.y > 0.5, "jump leaves the ground")
	await frames(90)
	check(game.player.is_on_floor(), "jump lands on collision geometry")
	# Walk into the west gatehouse: the wall must stop the capsule.
	game.player.position = Vector3(-7.8, 0.2, 18)
	game.player.yaw = 0
	game.player.velocity = Vector3.ZERO
	Input.action_press("forward")
	await frames(160)
	Input.action_release("forward")
	check(game.player.position.z > 8.8, "gatehouse stops player penetration")
	game.player.position = Vector3(0,0.2,-73)
	game.update_interaction()
	check(game.target.get("kind") == "enter", "Siwei entrance is reachable")
	game.interact()
	await frames(30)
	check(game.player.position.x > 290 and game.player.is_on_floor(), "interior transition lands safely")
	for i in range(3):
		game.target = {"kind":"story","index":i}
		game.interact()
		while game.hud.dialogue.visible:
			game.hud.advance_dialogue()
	check(game.collected.size() == 3, "three unique story rewards")
	game.target = {"kind":"story","index":0}
	game.interact()
	check(game.collected.size() == 3, "collected stories cannot be duplicated")
	game.target = {"kind":"npc","index":0}
	game.interact()
	check(game.completed, "principal completes the story quest")
	while game.hud.dialogue.visible:
		game.hud.advance_dialogue()
	game.return_to_gate()
	game.car.position = Vector3(20,0.2,25)
	game.car.rotation.y = PI / 2
	game.target = {"kind":"car"}
	game.interact()
	var car_start: Vector3 = game.car.position
	Input.action_press("forward")
	await frames(90)
	Input.action_release("forward")
	check(game.car.position.distance_to(car_start) > 2, "vehicle accelerates and moves")
	game.target = {"kind":"car"}
	game.interact()
	check(not game.player.driving, "vehicle finds a safe exit")
	game.save_progress()
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(saved.completed and saved.collected.size() == 3, "progress is persisted to JSON")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("INTEGRATION_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
