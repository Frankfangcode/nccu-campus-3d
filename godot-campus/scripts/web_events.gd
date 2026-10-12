extends Node3D
## 網頁 v1.24 的天氣事件、警察回合戰與騎馬老校長，使用同一份內容資料。
var game: Node3D
var weather: Dictionary
var principal_data: Dictionary
var raining := false
var holding := false
var rain_left := 0.0
var rain_hp := 100.0
var cooldown := 0.0
var cop_delay := -1.0
var cop: Node3D
var cop_chasing := false
var tile_clock := 0.0
var modal := false
var rain: CPUParticles3D
var ground_umbrella: Node3D
var held_umbrella: Node3D
var npc_umbrellas: Array[Node3D] = []
var lions: Array[Node3D] = []
var principal: Node3D
var route_index := 0
var waypoint := 1
var route_direction := 1
var ride_time := 0.0
var horse_legs: Array[Node3D] = []
var retry_left := 0.0
var quiz_index := 0
var questions: Array = []
var enemy_hp := 110.0
var battle_hp := 100.0
var heals := 0
var overlay: Control
var panel: VBoxContainer
var status: Label
var letter_button: Button
var environment: Environment
var sun: DirectionalLight3D
var base_sun := 0.8
var base_fog := 0.0012
var gloom := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	weather = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/weather.json"))
	principal_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/old-principal.json"))
	rng.randomize()
	for child in game.get_children():
		if child is WorldEnvironment:
			environment = child.environment
			base_fog = environment.fog_density
		if child is DirectionalLight3D:
			sun = child
			base_sun = sun.light_energy
	for x in [-56.2,-35.8]:
		var lion: Node3D = load("res://assets/models/weather_lion.glb").instantiate()
		add_child(lion)
		lion.position = Vector3(x,2.5,-83.6)
		lions.append(lion)
	principal = load("res://assets/models/old_principal.glb").instantiate()
	add_child(principal)
	var start: Array = principal_data.routes[0].points[0]
	principal.position = Vector3(start[0],0,start[1])
	for node in principal.find_children("*","Node3D",true,false):
		if absf(node.position.y-0.66)<0.01 and absf(absf(node.position.x)-0.17)<0.01:
			horse_legs.append(node)
	cop = load("res://scripts/actor.gd").new()
	add_child(cop)
	cop.setup()
	cop.hide()
	ground_umbrella = umbrella(Color("598ed6"))
	add_child(ground_umbrella)
	held_umbrella = umbrella(Color("598ed6"))
	game.player.visual.add_child(held_umbrella)
	held_umbrella.position = Vector3(0.3,2.0,0.05)
	for i in range(game.npcs.size()):
		var npc: Dictionary = game.npcs[i]
		if npc.data.get("indoor",false):
			continue
		var u := umbrella(Color.from_hsv(float(i)/game.npcs.size(),0.5,0.85))
		npc.node.add_child(u)
		u.position = Vector3(0.3,2.0,0.05)
		npc_umbrellas.append(u)
	build_rain()
	build_ui()

func umbrella(color: Color) -> Node3D:
	var root := Node3D.new()
	var canopy := CylinderMesh.new()
	canopy.top_radius = 0.0
	canopy.bottom_radius = 0.78
	canopy.height = 0.36
	canopy.radial_segments = 16
	mesh_part(root,canopy,Vector3.ZERO,color)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.018
	shaft.bottom_radius = 0.018
	shaft.height = 1.0
	mesh_part(root,shaft,Vector3(0,-0.5,0),Color("3a3d45"))
	root.visible = false
	return root

func mesh_part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	parent.add_child(instance)

func build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 450 if game.mobile else 1200
	rain.lifetime = 1.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(16,0.1,16)
	rain.direction = Vector3(0.05,-1,0.02)
	rain.spread = 1.0
	rain.initial_velocity_min = 22
	rain.initial_velocity_max = 26
	rain.gravity = Vector3.ZERO
	rain.local_coords = false
	var drop := BoxMesh.new()
	drop.size = Vector3(0.015,0.65,0.015)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c4d9e4")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = mat
	rain.mesh = drop
	rain.emitting = false
	add_child(rain)

func build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	status = Label.new()
	status.theme = game.hud.root.theme
	status.position = Vector2(24,110)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_color_override("font_shadow_color",Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x",2)
	status.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(status)
	letter_button = Button.new()
	letter_button.theme = game.hud.root.theme
	letter_button.text = "閱讀精神堡壘信函"
	letter_button.position = Vector2(24,290)
	letter_button.custom_minimum_size = Vector2(230,48)
	letter_button.pressed.connect(func(): show_message(principal_data.letter.name,principal_data.letter.lines))
	layer.add_child(letter_button)
	overlay = Control.new()
	overlay.theme = game.hud.root.theme
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.04,0.06,0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 28
	scroll.offset_right = -28
	scroll.offset_top = 24
	scroll.offset_bottom = -24
	overlay.add_child(scroll)
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation",12)
	scroll.add_child(panel)
	overlay.hide()

func choose(title: String, lines: Array, options: Array, callback: Callable) -> void:
	modal = true
	game.player.enabled = false
	game.player.touch_move = Vector2.ZERO
	if game.hud.touch:
		game.hud.touch.reset()
		game.hud.touch.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",26)
	panel.add_child(heading)
	var body := Label.new()
	body.text = "\n".join(PackedStringArray(lines))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",20)
	panel.add_child(body)
	for i in range(options.size()):
		var button := Button.new()
		button.text = str(options[i])
		button.custom_minimum_size.y = 54
		button.add_theme_font_size_override("font_size",20)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263a46")
		style.set_border_width_all(1)
		style.border_color = Color("738894")
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal",style)
		var hover: StyleBoxFlat = style.duplicate()
		hover.bg_color = Color("496674")
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",hover)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func(): close_modal(); callback.call(i))
		panel.add_child(button)
	overlay.show()

func close_modal() -> void:
	modal = false
	overlay.hide()
	game.player.enabled = game.playing and not game.hud.map_large
	if game.hud.touch:
		game.hud.touch.reset()
		game.hud.touch.visible = game.mobile and game.player.enabled
	if not game.mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_message(title: String, lines: Array, next: Callable = Callable()) -> void:
	choose(title,lines,["繼續"],func(_i):
		if next.is_valid(): next.call())

func start_rain() -> void:
	raining = true
	rain_left = weather.rain.seconds
	rain_hp = 100
	ground_umbrella.position = game.player.position + Basis(Vector3.UP,game.player.yaw)*Vector3(0,0.4,-2.5)
	ground_umbrella.visible = true
	game.hud.toast(weather.rain.start)

func stop_rain() -> void:
	raining = false
	holding = false
	held_umbrella.hide()
	ground_umbrella.hide()
	cop_delay = -1
	cop_chasing = false
	cop.hide()
	cooldown = weather.lion.cooldownSeconds
	game.hud.toast(weather.rain.stop)

func wake_lion() -> void:
	cooldown = weather.lion.cooldownSeconds
	var lion := lions[0]
	var home := lion.position
	var destination: Vector3 = game.player.position + Vector3(-1.8,0.1,-1.8)
	var tween := create_tween()
	tween.tween_property(lion,"position",destination+Vector3.UP*2,0.35)
	tween.tween_property(lion,"position",destination,0.35)
	choose(weather.lion.title,weather.lion.lines,weather.lion.choices,func(i):
		show_message(weather.lion.title,weather.lion.replies[i],func():
			start_rain()
			var back := create_tween()
			back.tween_property(lion,"position",home+Vector3.UP*2,0.35)
			back.tween_property(lion,"position",home,0.35)))

func take_umbrella() -> void:
	if not raining or holding: return
	ground_umbrella.hide()
	holding = true
	cop_delay = weather.umbrella.copDelaySeconds
	game.hud.toast(weather.umbrella.taken)

func candidates() -> void:
	if ground_umbrella.visible and not game.carrying:
		game.candidate("weather_umbrella",ground_umbrella.position,"E  撐傘",-1,3)
	game.candidate("old_principal",principal.position,"E  抓住老校長",-1,3.5)

func interact(kind: String) -> bool:
	if kind == "weather_umbrella": take_umbrella(); return true
	if kind == "old_principal": encounter_principal(); return true
	return false

func cop_talk() -> void:
	cop_chasing = false
	cop.hide()
	choose(weather.cop.title,weather.cop.lines,weather.cop.choices,func(i):
		if i == 0: ending(weather.cop.arrested)
		else: start_battle())

func start_battle() -> void:
	enemy_hp = weather.battle.enemy.hp
	battle_hp = weather.battle.player.hp
	heals = 0
	battle_menu(weather.battle.intro)

func battle_menu(lines: Array) -> void:
	var options: Array = []
	for move in weather.battle.playerMoves: options.append(move.name)
	choose("駐校警察  %d HP　｜　你  %d HP" % [enemy_hp,battle_hp],lines,options,battle_turn)

func battle_turn(index: int) -> void:
	var move: Dictionary = weather.battle.playerMoves[index]
	if move.get("run",false):
		holding = false
		show_message(weather.cop.title,[weather.cop.run])
		return
	var lines: Array = move.lines.duplicate()
	if move.has("heal"): battle_hp = minf(100,battle_hp+move.heal)
	elif rng.randf() <= move.get("accuracy",1): enemy_hp = maxf(0,enemy_hp-rng.randi_range(move.power[0],move.power[1]))
	else: lines.append(weather.battle.messages.miss)
	if enemy_hp <= 0:
		show_message(weather.cop.title,weather.battle.messages.enemyFaint)
		return
	var enemy: Dictionary
	if enemy_hp < 49.5 and heals < 2 and rng.randf() < 0.55:
		enemy = weather.battle.enemyMoves[0]
		enemy_hp = minf(110,enemy_hp+enemy.heal)
		heals += 1
	else:
		enemy = weather.battle.enemyMoves[2 if rng.randf()<0.28 else 1]
		if enemy.has("power"):
			if rng.randf() <= enemy.accuracy: battle_hp = maxf(0,battle_hp-rng.randi_range(enemy.power[0],enemy.power[1]))
			else: lines.append(weather.battle.messages.miss)
	lines.append_array(enemy.lines)
	if battle_hp <= 0:
		holding = false
		game.player.position = Vector3(0,0.2,14)
		show_message(weather.cop.title,[weather.cop.lose])
	else: battle_menu(lines)

func ending(data: Dictionary) -> void:
	choose(data.title,[data.sub],["回校門重新出發"],func(_i):
		stop_rain()
		game.player.position = Vector3(-2,0.2,21)
		game.player.velocity = Vector3.ZERO
		game.player.stamina = 100)

func splash() -> void:
	var spray := CPUParticles3D.new()
	spray.amount = 40
	spray.one_shot = true
	spray.explosiveness = 1.0
	spray.lifetime = 0.8
	spray.direction = Vector3.UP
	spray.spread = 65
	spray.initial_velocity_min = 3
	spray.initial_velocity_max = 7
	spray.gravity = Vector3(0,-18,0)
	var drop := SphereMesh.new()
	drop.radius = 0.055
	drop.height = 0.11
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("bfe3f5")
	drop.material = material
	spray.mesh = drop
	add_child(spray)
	spray.global_position = game.player.position+Vector3.UP*0.1
	spray.finished.connect(spray.queue_free)
	spray.emitting = true
	show_message("四維道",weather.tile.lines,func(): ending(weather.tile.ending))

func encounter_principal() -> void:
	choose(principal_data.title,principal_data.caught,principal_data.askStudent,func(i):
		if i != 0: show_message(principal_data.title,principal_data.notStudent)
		elif game.have_letter: show_message(principal_data.title,principal_data.alreadyDone)
		elif retry_left > 0: show_message(principal_data.title,principal_data.cooldown)
		else:
			choose(principal_data.title,principal_data.invite,principal_data.acceptChoices,func(k):
				if k == 0: start_quiz()
				else: show_message(principal_data.title,principal_data.decline)))

func start_quiz() -> void:
	questions = principal_data.quiz.duplicate(true)
	quiz_index = 0
	ask_question()

func ask_question() -> void:
	var q: Dictionary = questions[quiz_index]
	var order: Array = range(q.options.size())
	if principal_data.shuffle: order.shuffle()
	var options: Array = []
	for i in order: options.append(q.options[i])
	choose("校史問答 %d / %d" % [quiz_index+1,questions.size()],[q.q],options,func(index): answer_question(order[index]))

func answer_question(index: int) -> void:
	var q: Dictionary = questions[quiz_index]
	if index != int(q.answer):
		retry_left = principal_data.retrySeconds
		var lines: Array = ["答錯了。正確答案："+str(q.options[int(q.answer)])]
		for line in principal_data.fail: lines.append(str(line).replace("{score}",str(quiz_index)))
		show_message(principal_data.title,lines)
		return
	quiz_index += 1
	if quiz_index == questions.size():
		game.have_letter = true
		game.save_progress()
		show_message(principal_data.title,principal_data.pass)
	else:
		show_message(principal_data.title,["答對了！"],ask_question)

func update_principal(delta: float) -> void:
	var route: Dictionary = principal_data.routes[route_index]
	var point: Array = route.points[waypoint]
	var destination := Vector3(point[0],0,point[1])
	var offset := destination-principal.position
	offset.y = 0
	ride_time += delta
	var speed: float = principal_data.speed.walk if fmod(ride_time,14)>8 else principal_data.speed.gallop
	if offset.length() < 1.2:
		waypoint += route_direction
		if waypoint >= route.points.size() or waypoint < 0:
			if route.loop: waypoint = 0
			else:
				route_direction *= -1
				waypoint = clampi(waypoint,0,route.points.size()-1)
			var other: int = 1-route_index
			var start: Array = principal_data.routes[other].points[0]
			if principal.position.distance_to(game.player.position)>60 and Vector3(start[0],0,start[1]).distance_to(game.player.position)>60:
				route_index = other
				principal.position = Vector3(start[0],0,start[1])
				waypoint = 1
				route_direction = 1
	else:
		principal.position += offset.normalized()*minf(offset.length(),speed*delta)
		principal.rotation.y = lerp_angle(principal.rotation.y,atan2(offset.x,offset.z),1-exp(-delta*5))
	principal.position.y = absf(sin(ride_time*13))*0.06 if speed>3 else 0.0
	for i in range(horse_legs.size()):
		horse_legs[i].rotation.x = sin(ride_time*(13 if speed>3 else 6)+i*PI*0.7)*(0.65 if speed>3 else 0.3)

func _process(delta: float) -> void:
	letter_button.visible = game.have_letter and game.playing and not modal and not game.hud.map_large
	var viewport_size := get_viewport().get_visible_rect().size
	letter_button.position = Vector2(viewport_size.x-260,195)
	var outside: bool = game.player.position.x < 250
	held_umbrella.visible = holding and outside and not game.player.driving
	game.player.visual.umbrella_active = held_umbrella.visible
	for u in npc_umbrellas:
		u.visible = raining
		u.get_parent().umbrella_active = raining
	gloom = lerpf(gloom,1.0 if raining else 0.0,1-exp(-delta*0.8))
	if sun: sun.light_energy = base_sun*(1.0-gloom*0.7)
	if environment: environment.fog_density = base_fog+gloom*0.002
	rain.global_position = game.player.position+Vector3.UP*20
	rain.emitting = raining and outside
	status.visible = raining and game.playing and not modal and not game.hud.map_large
	status.text = "雨天體力 %d / 100　%s" % [ceili(rain_hp),"撐傘中" if holding else ("室內避雨" if not outside else "找地方躲雨")]
	if not game.playing or not game.player.enabled or modal: return
	cooldown = maxf(0,cooldown-delta)
	retry_left = maxf(0,retry_left-delta)
	update_principal(delta)
	if not raining:
		var trigger: Dictionary = weather.lion.trigger
		if cooldown<=0 and not game.player.driving and game.player.position.distance_to(Vector3(trigger.x,0,trigger.z))<trigger.r: wake_lion()
		return
	rain_left -= delta
	if rain_left <= 0: stop_rain(); return
	if outside and not holding and not game.player.driving:
		rain_hp = maxf(0,rain_hp-weather.rain.drainPerSecond*delta)
		if rain_hp<=0: ending(weather.rain.soaked); return
	if cop_chasing:
		var offset: Vector3 = game.player.position-cop.position
		if offset.length()<2.5: cop_talk(); return
		cop.position += offset.normalized()*minf(offset.length(),delta*7)
		cop.rotation.y = atan2(offset.x,offset.z)
		cop.animate(7)
	if cop_delay >= 0:
		cop_delay -= delta
		if cop_delay<0 and holding:
			cop.position = game.player.position+Basis(Vector3.UP,game.player.yaw)*Vector3(0,0,12)
			cop.show()
			cop_chasing = true
			game.hud.toast(weather.cop.shout)
	tile_clock -= delta
	if tile_clock<=0:
		tile_clock = 1
		var p: Vector3 = game.player.position
		if outside and not game.player.driving and p.x>-96 and p.x < 66 and absf(p.z-(-60.2+0.18*p.x))<5.2 and game.player.velocity.length()>1 and rng.randf()<weather.tile.chancePerSecond:
			splash()
