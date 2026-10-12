extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/campus.tscn").instantiate()
	root.add_child(game)
	game.hud.root.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 64
	for spec in [["law-photo-rebuilt",Vector3(-147,16,-108),Vector3(-110,14,-78)],["pool-photo-rebuilt",Vector3(-90,8,-93),Vector3(-125,5,-120)]]:
		camera.position = spec[1]
		camera.look_at(spec[2])
		for i in range(15):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/"+spec[0]+".png")
	quit()
