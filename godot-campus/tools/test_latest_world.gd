extends SceneTree
## 確認新版建築在編輯器場景、實體碰撞、地圖與導航都存在。
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/campus.tscn").instantiate()
	game.save_path = "user://latest_world_test_save.json"
	var architecture: Node = game.get_node("Architecture")
	for id in ["computer-center","lohas-hall","jiying-hall","daren-hall","command-stand","guofu-hall","zhixi-hall","track"]:
		var node: Node = architecture.find_child("Building_"+id,true,false)
		assert(is_instance_valid(node),"編輯器場景缺少建築 "+id)
		assert(node.find_children("*","MeshInstance3D",true,false).size()>0,"建築沒有實體模型 "+id)
	root.add_child(game)
	game.set_playing(true)
	game.web_events.set_process(false)
	for spec in [["電算中心",Vector3(70,0,-43)],["資訊大樓",Vector3(40,0,-31)],["樂活館",Vector3(38,0,-5)],["集英樓",Vector3(112,0,-4)],["大仁樓",Vector3(150,0,-21)],["司令台",Vector3(54,0,-112)],["羅馬廣場",Vector3(90,0,-59)]]:
		var found := false
		for poi in game.navigation.pois:
			if poi.name==spec[0]: found = true
		assert(found,"導航缺少建築 "+spec[0])
		var target: Vector3 = spec[1]
		game.player.position = Vector3(0,0.3,10)
		game.navigation.select_destination(target,spec[0],false)
		assert(game.navigation.route_available,"找不到建築路線 "+spec[0])
		print("LATEST_BUILDING_PASS ",spec[0])
	# 塔樓實牆與樂活館平台需有物理表面，不能只有貼圖。
	await physics_frame
	for p in [Vector3(70,0,-30),Vector3(150,0,-13),Vector3(112,0,-14)]:
		var q := PhysicsRayQueryParameters3D.create(p+Vector3.UP*20,p+Vector3.DOWN,1)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
		assert(not hit.is_empty() and hit.position.y>1,"新增建築缺少碰撞")
	if "--snapshot" in OS.get_cmdline_user_args():
		game.hud.root.hide()
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.current = true
		for spec in [["new-computer-center",Vector3(110,30,8),Vector3(65,8,-24)],["new-lohas-jiying",Vector3(67,32,42),Vector3(69,3,-3)],["new-daren",Vector3(173,14,-36),Vector3(150,4,-13)],["new-track-stand",Vector3(38,24,-83),Vector3(66,3,-120)]]:
			camera.position = spec[1]
			camera.look_at(spec[2])
			for i in range(10): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/"+spec[0]+".png")
	print("LATEST_WORLD_PASS")
	quit()
