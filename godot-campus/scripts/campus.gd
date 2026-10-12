extends Node3D
## Campus geometry and dialogue are migrated from the original Three.js game.
const Player = preload("res://scripts/player.gd")
const Actor = preload("res://scripts/actor.gd")
const Hud = preload("res://scripts/hud.gd")
const Navigation = preload("res://scripts/navigation.gd")
var architecture_detail: Node3D
var navigation: Node
var saved_discoveries: Array = []
var test_clock := 0.0
var mobile := false
var data: Dictionary
var player: CharacterBody3D
var hud: CanvasLayer
var collected: Array = []
var completed := false
var badge := false
var npcs: Array = []
var markers: Array = []
var pangolin: Node3D
var car: CharacterBody3D
var carrying := false
var car_speed := 0.0
var elapsed := 0.0
var target: Dictionary = {}
var playing := false
var save_clock := 0.0
var capture_frames := 0
var save_path := "user://campus_save.json"

func _ready() -> void:
	print("CAMPUS_BUILD start")
	# The migrated physics and quest data use meters in this original coordinate frame.
	# Keep architecture, physics and mission positions in that same coordinate frame.
	$Architecture.scale = Vector3.ONE
	mobile = DisplayServer.is_touchscreen_available() or "--mobile-test" in OS.get_cmdline_user_args()
	if mobile:
		configure_mobile()
		get_tree().root.size_changed.connect(configure_mobile)
	if OS.has_feature("web"):
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	configure_input()
	print("CAMPUS_BUILD input ready")
	print("CAMPUS_BUILD browser ready")
	if "--test" in OS.get_cmdline_user_args():
		save_path = "user://campus_test_save.json"
	data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/campus.json"))
	print("CAMPUS_BUILD data ready")
	build_environment()
	print("CAMPUS_BUILD materials")
	upgrade_materials()
	build_grading()
	print("CAMPUS_BUILD collision")
	build_collisions()
	architecture_detail = $PhotoReferencedArchitecture
	architecture_detail.initialize(self)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = Vector3(-2, 0.2, 21)
	print("CAMPUS_BUILD actors")
	build_actors()
	build_stories()
	load_progress()
	navigation = Navigation.new()
	navigation.game = self
	add_child(navigation)
	navigation.discovered = saved_discoveries.duplicate()
	# A previously saved position may now be inside a newly constructed building.
	if player.position.x < 250:
		var saved_cell: Vector2i = navigation.cell(Vector2(player.position.x,player.position.z))
		if navigation.grid.is_in_boundsv(saved_cell) and navigation.grid.is_point_solid(saved_cell):
			var safe_cell: Vector2i = navigation.nearest_open(Vector2(player.position.x,player.position.z))
			var safe_point: Vector2 = navigation.grid.get_point_position(safe_cell)
			player.position = Vector3(safe_point.x,0.2,safe_point.y)
	hud = Hud.new()
	hud.game = self
	print("CAMPUS_BUILD hud")
	add_child(hud)
	if "--capture" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args():
		set_playing(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if "--avenue" in OS.get_cmdline_user_args():
			player.position = Vector3(-3.5, 0.2, -19)
			player.yaw = -0.2
		if "--interior" in OS.get_cmdline_user_args():
			player.position = Vector3(300, 0.2, 18)
		if "--atlas" in OS.get_cmdline_user_args():
			hud.toggle_map.call_deferred()
		if "--law" in OS.get_cmdline_user_args():
			player.position = Vector3(-110,0.2,-100)
			player.yaw = 0.30
			player.pitch = 0.22
			player.arm.spring_length = 8.0
			var architecture_camera := Camera3D.new()
			add_child(architecture_camera)
			architecture_camera.position = Vector3(-155,15,-105)
			architecture_camera.look_at(Vector3(-110,13,-78))
			architecture_camera.fov = 60
			architecture_camera.current = true
		if "--street" in OS.get_cmdline_user_args():
			player.position = Vector3(6,0.2,33)
			player.yaw = PI-0.7
			player.pitch = 0.05
		if "--jing-tang" in OS.get_cmdline_user_args() or "--journalism" in OS.get_cmdline_user_args():
			var reference_camera := Camera3D.new()
			add_child(reference_camera)
			var journalism_view := "--journalism" in OS.get_cmdline_user_args()
			reference_camera.position = Vector3(126,11,-7) if journalism_view else Vector3(-185,10,-84)
			reference_camera.look_at(Vector3(112,4,-25) if journalism_view else Vector3(-193,6,-112))
			reference_camera.current = true
		for shot in ["--route","--pool","--preschool"]:
			if shot in OS.get_cmdline_user_args():
				var survey_camera := Camera3D.new()
				add_child(survey_camera)
				var eyes := {"--route":Vector3(-232,73,-20),"--pool":Vector3(-157,10,-98),"--preschool":Vector3(-178,9,-64)}
				var targets := {"--route":Vector3(-145,0,-81),"--pool":Vector3(-123,4,-120),"--preschool":Vector3(-166,5,-33)}
				survey_camera.position = eyes[shot]
				survey_camera.look_at(targets[shot])
				survey_camera.fov = 62
				survey_camera.current = true
		if "--walk" in OS.get_cmdline_user_args():
			visit_photo_route()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if "--clean" in OS.get_cmdline_user_args():
			hud.root.hide()
	print("CAMPUS_READY npc=", npcs.size(), " stories=", markers.size())
	if "--quality-low" in OS.get_cmdline_user_args():
		get_viewport().scaling_3d_scale = 0.65
		for light in find_children("*","DirectionalLight3D",true,false):
			light.shadow_enabled = false
	elif "--quality-high" in OS.get_cmdline_user_args():
		get_viewport().scaling_3d_scale = 1.0

func configure_mobile() -> void:
	var dimensions := DisplayServer.window_get_size()
	get_tree().root.content_scale_size = Vector2i(960,540) if dimensions.x>dimensions.y else Vector2i(540,960)
	get_viewport().scaling_3d_scale = 0.7

func visit_photo_route() -> void:
	if player.driving:
		return_to_gate()
	player.position = Vector3(-80,0.2,-57)
	player.velocity = Vector3.ZERO
	player.yaw = PI/2
	player.pitch = 0.08
	navigation.select_destination($PhotoReferencedArchitecture/JingTang/Entrance.global_position,"教育學院・井塘樓")
	set_playing(true)

func configure_input() -> void:
	var actions := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "jump": KEY_SPACE, "interact": KEY_E, "map": KEY_M, "menu": KEY_ESCAPE}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = actions[action]
		InputMap.action_add_event(action, event)
	for entry in [["forward",JOY_AXIS_LEFT_Y,-1.0],["back",JOY_AXIS_LEFT_Y,1.0],["left",JOY_AXIS_LEFT_X,-1.0],["right",JOY_AXIS_LEFT_X,1.0]]:
		var joy := InputEventJoypadMotion.new()
		joy.axis = entry[1]
		joy.axis_value = entry[2]
		InputMap.action_add_event(entry[0], joy)

func build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("668eab")
	sky_mat.sky_horizon_color = Color("d5d9cc")
	sky_mat.ground_bottom_color = Color("49514b")
	sky_mat.ground_horizon_color = Color("d5d9cc")
	sky_mat.sun_angle_max = 2.0
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("abbfd0")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("c2cfcb")
	env.fog_density = 0.0012
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -42, 0)
	sun.light_color = Color("ffe0a9")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if OS.has_feature("web") else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 70.0 if OS.has_feature("web") else 160.0
	sun.shadow_bias = 0.04
	add_child(sun)
	for z in [-15.0, 5.0, 20.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(300, 6, z)
		light.omni_range = 30
		light.light_color = Color("ffe1ac")
		light.light_energy = 2.3
		add_child(light)

func upgrade_materials() -> void:
	var cache := {}
	var texture_sets := {"asphalt": "asphalt_02", "paving": "pavement_02", "brick": "brown_brick_02", "terrain": "aerial_grass_rock"}
	for node in $Architecture.find_children("*", "MeshInstance3D", true, false):
		for slot in range(node.mesh.get_surface_count()):
			var original: Material = node.mesh.surface_get_material(slot)
			if not original is StandardMaterial3D:
				continue
			var key := original.get_instance_id()
			if cache.has(key):
				node.set_surface_override_material(slot, cache[key])
				continue
			var mat: StandardMaterial3D = original.duplicate()
			var kind := mat.resource_name.get_slice("_", 0)
			var bounds: AABB = node.global_transform * node.get_aabb()
			if bounds.end.y > 75 and bounds.position.z < -200:
				mat.albedo_color = Color("506453")
				mat.albedo_texture = load("res://assets/textures/aerial_grass_rock_albedo.jpg")
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3.ONE * 0.04
				mat.roughness = 1.0
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if texture_sets.has(kind):
				var prefix: String = "res://assets/textures/" + texture_sets[kind]
				mat.albedo_texture = load(prefix + "_albedo.jpg")
				mat.normal_enabled = true
				mat.normal_texture = load(prefix + "_normal.jpg")
				mat.normal_scale = 0.8
				mat.roughness_texture = load(prefix + "_roughness.jpg")
				mat.roughness = 0.93
				mat.albedo_color = Color(0.8,0.83,0.78) if kind == "terrain" else Color.WHITE
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3.ONE * (0.3 if kind == "terrain" else 0.5)
			if kind == "green":
				mat.roughness = 1.0
				mat.albedo_color = mat.albedo_color.lerp(Color("4e603b"), 0.35)
			if kind == "water":
				var shader := Shader.new()
				shader.code = "shader_type spatial; render_mode cull_disabled; void fragment(){ float w=sin(VERTEX.x*2.0+TIME)*cos(VERTEX.z*1.6+TIME*0.7); ALBEDO=mix(vec3(0.065,0.19,0.18),vec3(0.18,0.34,0.32),w*0.5+0.5); ROUGHNESS=0.2; METALLIC=0.45; NORMAL=normalize(NORMAL+vec3(w*0.08,0.0,w*0.08)); }"
				var water := ShaderMaterial.new()
				water.shader = shader
				cache[key] = water
				node.set_surface_override_material(slot, water)
				continue
			cache[key] = mat
			node.set_surface_override_material(slot, mat)

func build_grading() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var screen := ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_linear; void fragment(){vec3 c=texture(screen_texture,SCREEN_UV).rgb; float l=dot(c,vec3(0.2126,0.7152,0.0722)); c=mix(vec3(l),c,0.86); c=(c-0.5)*1.04+0.5; vec2 p=SCREEN_UV*2.0-1.0; c*=1.0-0.16*dot(p,p)*0.5; COLOR=vec4(c,1.0);}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	screen.material = mat
	layer.add_child(screen)

func solid(shape: Shape3D, pos: Vector3, yaw: float = 0.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	body.rotation.y = yaw
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func build_collisions() -> void:
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(1400, 1, 1400)
	solid(floor_shape, Vector3(0, -0.5, -200))
	for c in data.colliders:
		var height: float = maxf(float(c.get("top", 4.0)), 0.15)
		if c.get("c", false):
			var cylinder := CylinderShape3D.new()
			cylinder.radius = maxf(c.r, 0.1)
			cylinder.height = height
			solid(cylinder, Vector3(c.x, height / 2, c.z))
		else:
			var shape := BoxShape3D.new()
			if c.get("obb", false):
				shape.size = Vector3(c.hx * 2, height, c.hz * 2)
				solid(shape, Vector3(c.cx, height / 2, c.cz), -atan2(c.sn, c.cs))
			else:
				shape.size = Vector3(maxf(0.05, c.x1 - c.x0), height, maxf(0.05, c.z1 - c.z0))
				solid(shape, Vector3((c.x0+c.x1)/2, height/2, (c.z0+c.z1)/2))
	# Exact floor/stairs in the detached Siwei Hall interior.
	for node in $Architecture.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = node.global_transform * node.get_aabb()
		if box.position.x > 265 and box.end.x < 335 and box.size.y < 3:
			node.create_trimesh_collision()

func build_actors() -> void:
	for i in range(data.npcs.size()):
		var info: Dictionary = data.npcs[i]
		var actor := Actor.new()
		add_child(actor)
		actor.setup(i % 3 == 1)
		actor.position = Vector3(info.home.x, 0.03, info.home.z)
		actor.rotation.y = info.face
		var title := Label3D.new()
		title.text = info.title
		title.font = load("res://assets/fonts/NotoSansTC-Game.ttf" if OS.has_feature("web") else "res://assets/fonts/NotoSansTC.ttf")
		title.font_size = 32
		title.pixel_size = 0.007
		title.position.y = 2.15
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.modulate = Color("f9e4ba")
		title.visibility_range_end = 13
		actor.add_child(title)
		npcs.append({"node":actor, "data":info, "waypoint":0})
	pangolin = load("res://assets/models/pangolin.glb").instantiate()
	add_child(pangolin)
	pangolin.position = Vector3(-3, 0.1, 8)
	car = CharacterBody3D.new()
	car.collision_layer = 4
	car.collision_mask = 1
	add_child(car)
	car.position = Vector3(data.police.x, 0.1, data.police.z)
	car.rotation.y = data.police.yaw
	car.add_child(load("res://assets/models/police.glb").instantiate())
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 3.8)
	collider.shape = box
	collider.position.y = 0.7
	car.add_child(collider)

func build_stories() -> void:
	for info in data.stories:
		var node := Node3D.new()
		add_child(node)
		var p: Array = info.position
		node.position = Vector3(p[0], p[1], p[2])
		var mesh := MeshInstance3D.new()
		var crystal := PrismMesh.new()
		crystal.size = Vector3(0.32, 0.75, 0.32)
		mesh.mesh = crystal
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("e3bc66")
		mat.metallic = 0.7
		mat.roughness = 0.2
		mat.emission_enabled = true
		mat.emission = Color("bc8c31")
		mesh.material_override = mat
		node.add_child(mesh)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.48
		torus.outer_radius = 0.52
		ring.mesh = torus
		ring.material_override = mat
		ring.position.y = -0.7
		node.add_child(ring)
		markers.append(node)

func set_playing(value: bool) -> void:
	playing = value
	player.enabled = value
	hud.menu.visible = not value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value and not mobile else Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(hud.touch):
		hud.touch.reset()
	print("CAMPUS_PLAYING ", value)
	if not value:
		save_progress()

func return_to_gate() -> void:
	if player.driving:
		player.driving = false
		car_speed = 0
	player.position = Vector3(-2, 0.2, 21)
	player.velocity = Vector3.ZERO
	player.yaw = 0
	player.pitch = -0.16

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if hud.map_large:
			hud.toggle_map()
			return
		if hud.dialogue.visible:
			hud.dialogue.hide()
		set_playing(not playing)
	if event.is_action_pressed("map") and playing:
		hud.toggle_map()
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if hud.dialogue.visible:
			hud.advance_dialogue()
		elif playing:
			interact()
	if event is InputEventMouseButton and event.pressed and playing and not hud.dialogue.visible and not hud.map_large and not mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	elapsed += delta
	if "--test-browser" in OS.get_cmdline_user_args():
		test_clock += delta
		if test_clock>0.5:
			test_clock = 0
			var route_button: Rect2 = hud.route_visit_button.get_global_rect()
			print("TEST_STATE ",JSON.stringify({"x":player.position.x,"z":player.position.z,"yaw":player.yaw,"map":hud.map_large,"playing":playing,"mobile":mobile,"stick":player.touch_move.length(),"sprint":player.touch_sprint,"fps":Engine.get_frames_per_second(),"destination":navigation.destination_name,"route_button":[route_button.position.x,route_button.position.y,route_button.size.x,route_button.size.y]}))
	if playing:
		update_npcs(delta)
		if player.driving:
			update_car(delta)
		update_interaction()
	if carrying:
		pangolin.position = player.position + Basis(Vector3.UP, player.visual.rotation.y) * Vector3(0, 0.9, 0.6)
		pangolin.rotation.y = player.visual.rotation.y
	for i in range(markers.size()):
		markers[i].visible = not i in collected
		markers[i].rotation.y += delta * 0.7
		markers[i].get_child(0).position.y = sin(elapsed * 2 + i) * 0.13
	save_clock += delta
	if save_clock > 15 and playing:
		save_progress()
		save_clock = 0
	if "--capture" in OS.get_cmdline_user_args():
		capture_frames += 1
		if capture_frames == 90:
			capture.call_deferred()
	if "--smoke" in OS.get_cmdline_user_args() and elapsed > 2:
		run_smoke()

func update_npcs(delta: float) -> void:
	for npc in npcs:
		var actor: Node3D = npc.node
		if actor.position.distance_to(player.position) > 90:
			continue
		var path: Array = npc.data.path
		if path.size() < 2 or actor.position.distance_to(player.position) < 2.8:
			actor.animate(0)
			continue
		var dest := Vector3(path[npc.waypoint][0], 0.03, path[npc.waypoint][1])
		var direction := dest - actor.position
		if direction.length() < 0.3:
			npc.waypoint = (npc.waypoint + 1) % path.size()
		else:
			actor.position += direction.normalized() * delta * npc.data.speed
			actor.rotation.y = lerp_angle(actor.rotation.y, atan2(direction.x, direction.z), delta * 4)
			actor.animate(npc.data.speed)

func update_car(delta: float) -> void:
	var throttle := clampf(Input.get_axis("back", "forward")-player.touch_move.y,-1,1) if player.enabled else 0.0
	if player.touch_jump:
		throttle = 0
		car_speed = move_toward(car_speed,0,delta*30)
	car_speed = move_toward(car_speed, throttle * 16.0, delta * (8 if throttle else 10))
	var steer := clampf(Input.get_axis("right", "left")-player.touch_move.x,-1,1) if player.enabled else 0.0
	car.rotation.y += steer * delta * car_speed * 0.055
	car.velocity = -car.global_basis.z * car_speed
	car.velocity.y = -2
	car.move_and_slide()
	for i in range(car.get_slide_collision_count()):
		if absf(car.get_slide_collision(i).get_normal().y) < 0.5:
			car_speed *= 0.6
			break
	player.position = car.position + Vector3(0, 1, 0)
	if not mobile and Time.get_ticks_msec() > player.manual_look_until and absf(car_speed)>0.5 and (not is_instance_valid(hud.touch) or hud.touch.look_id == -1):
		player.yaw = lerp_angle(player.yaw, car.rotation.y, 1.0-exp(-delta*1.2))
	player.arm.spring_length = 7

func candidate(kind: String, pos: Vector3, text: String, index: int = -1, radius: float = 3.0) -> void:
	var distance := player.position.distance_to(pos)
	if distance < radius and (target.is_empty() or distance < target.distance):
		target = {"kind":kind, "index":index, "distance":distance, "text":text}

func update_interaction() -> void:
	target = {}
	if player.driving:
		target = {"kind":"car", "text":"E  下車", "distance":0}
	else:
		for i in range(npcs.size()):
			candidate("npc", npcs[i].node.position, "E  與%s交談" % npcs[i].data.title, i)
		for i in range(markers.size()):
			if not i in collected:
				candidate("story", markers[i].position, "E  拾起校園記憶", i)
		candidate("enter", Vector3(0, 0, -73), "E  進入四維堂", -1, 4)
		candidate("exit", Vector3(300, 0, 22), "E  返回校園", -1, 3)
		candidate("car", car.position, "E  駕駛巡邏車", -1, 4)
		candidate("pangolin", pangolin.position, "E  放下穿山甲" if carrying else "E  抱起穿山甲", -1, 2.5)
	hud.prompt.text = str(target.get("text", "")) if not hud.dialogue.visible else ""

func interact() -> void:
	if target.is_empty():
		return
	match target.kind:
		"story":
			var index: int = target.index
			if not index in collected:
				collected.append(index)
				navigation.auto_destination()
				hud.show_dialogue(data.stories[index].name, data.stories[index].lines)
				hud.toast("校園記憶  %d / 3" % collected.size())
				save_progress()
		"npc":
			var info: Dictionary = npcs[target.index].data
			if target.index == 0 and collected.size() == 3:
				completed = true
				navigation.auto_destination()
				hud.show_dialogue(info.title, ["你找回了校名碑、醉夢溪與四維堂的故事。", "恭喜完成校園記憶！這座校園也會繼續收藏你的故事。"])
				save_progress()
			else:
				hud.show_dialogue(info.title, info.lines)
				if target.index == 3 and not badge:
					badge = true
					hud.toast("獲得紀念徽章 · 校園記者")
		"enter":
			player.position = Vector3(300, 0.2, 20)
			player.yaw = 0
		"exit":
			player.position = Vector3(0, 0.2, -69)
			player.yaw = PI
		"pangolin":
			carrying = not carrying
			if not carrying:
				pangolin.position.y = 0.1
			else:
				hud.toast("校警提醒：請溫柔對待校園的小訪客。")
		"car":
			if player.driving:
				# Pick a clear exit point using the player's capsule against world geometry.
				var exited := false
				for offset in [Vector3(2.5,0.3,0), Vector3(-2.5,0.3,0), Vector3(0,0.3,3.5)]:
					var pos: Vector3 = car.position + car.basis * offset
					var test := PhysicsShapeQueryParameters3D.new()
					test.shape = player.get_child(0).shape
					test.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0,0.9,0))
					test.collision_mask = 1
					if get_world_3d().direct_space_state.intersect_shape(test, 1).is_empty():
						player.driving = false
						player.position = pos
						exited = true
						break
				if not exited:
					hud.toast("這裡沒有下車空間，請把車移到空曠處。")
				player.arm.spring_length = 4.8
				car_speed = 0
			else:
				if carrying:
					carrying = false
					pangolin.position.y = 0.1
				player.driving = true

func save_progress() -> void:
	var pos := player.position
	if player.driving:
		pos = Vector3(-2, 0.2, 21)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version":1,"collected":collected,"completed":completed,"badge":badge,"position":[pos.x,pos.y,pos.z],"discovered":navigation.discovered if is_instance_valid(navigation) else []}))

func load_progress() -> void:
	if "--smoke" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args() or "--test" in OS.get_cmdline_user_args():
		return
	if not FileAccess.file_exists(save_path):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not saved is Dictionary or saved.get("version",0) != 1:
		return
	for index in saved.get("collected", []):
		if int(index) >= 0 and int(index) < 3 and not int(index) in collected:
			collected.append(int(index))
	completed = saved.get("completed",false)
	badge = saved.get("badge",false)
	saved_discoveries = saved.get("discovered",[])
	var p = saved.get("position",[-2,0.2,21])
	if p is Array and p.size() == 3:
		player.position = Vector3(p[0],maxf(0.2,p[1]),p[2])

func capture() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var filename := "interior" if "--interior" in OS.get_cmdline_user_args() else ("avenue" if "--avenue" in OS.get_cmdline_user_args() else "campus")
	if "--atlas" in OS.get_cmdline_user_args():
		filename = "atlas"
	if "--law" in OS.get_cmdline_user_args():
		filename = "law-college"
	if "--street" in OS.get_cmdline_user_args():
		filename = "zhinan-street"
	if "--jing-tang" in OS.get_cmdline_user_args():
		filename = "jing-tang"
	if "--journalism" in OS.get_cmdline_user_args():
		filename = "journalism"
	for shot in ["route","pool","preschool","walk"]:
		if "--"+shot in OS.get_cmdline_user_args():
			filename = "photo-"+shot
	if mobile:
		filename += "-mobile"
	get_viewport().get_texture().get_image().save_png("res://artifacts/" + filename + ".png")
	print("CAPTURE_SAVED")
	get_tree().quit()

func run_smoke() -> void:
	assert(npcs.size() == data.npcs.size())
	assert(markers.size() == 3)
	assert(player.is_on_floor(), "Player should stand on the ground")
	player.position = Vector3(0,0.2,-73)
	update_interaction()
	assert(target.get("kind") == "enter")
	interact()
	assert(player.position.x == 300)
	target = {"kind":"exit"}
	interact()
	assert(player.position.x == 0)
	print("SMOKE_PASS: spawn, collision, NPCs, story markers, interior transitions")
	get_tree().quit()
