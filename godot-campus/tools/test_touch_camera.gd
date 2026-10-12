extends SceneTree
## 同時移動、轉視角、第三指及重排畫面時，鏡頭的觸點不可跳換。
func _initialize() -> void:
	run.call_deferred()

func touch(controls: Control, id: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	controls._input(event)

func drag(controls: Control, id: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	controls._input(event)

func run() -> void:
	var game = load("res://scenes/campus.tscn").instantiate()
	root.add_child(game)
	game.mobile = true
	game.set_playing(true)
	var controls = load("res://scripts/touch_controls.gd").new()
	controls.game = game
	root.add_child(controls)
	controls.layout(Vector2(1000,600))
	touch(controls,1,controls.origin,true)
	touch(controls,2,Vector2(580,260),true)
	var initial: float = game.player.yaw
	drag(controls,2,Vector2(640,260))
	assert(is_equal_approx(game.player.yaw,initial-0.22))
	var held: float = game.player.yaw
	touch(controls,3,Vector2(710,270),true)
	drag(controls,3,Vector2(810,270))
	assert(game.player.yaw == held and controls.look_id == 2)
	drag(controls,1,controls.origin+Vector2(0,-40))
	assert(game.player.touch_move.length()>0.5 and game.player.yaw==held)
	drag(controls,2,Vector2(50,570))
	assert(game.player.yaw==held,"異常大跳點不可轉動鏡頭")
	touch(controls,2,Vector2(50,570),false)
	touch(controls,4,Vector2(700,260),true)
	drag(controls,4,Vector2(730,260))
	assert(is_equal_approx(game.player.yaw,held-0.11),"新手指不可接續舊座標")
	controls.layout(Vector2(600,1000))
	assert(controls.look_id==-1 and controls.move_id==-1 and game.player.touch_move==Vector2.ZERO)
	var before: float = game.player.yaw
	touch(controls,5,Vector2(350,350),true)
	drag(controls,5,Vector2(410,350))
	assert(is_equal_approx(game.player.yaw,before-0.22),"橫直向靈敏度必須一致")
	controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(controls.look_id==-1)
	game.player.driving = true
	game.player.manual_look_until = Time.get_ticks_msec()+2000
	game.player.yaw = 1.1
	game.update_car(0.016)
	assert(is_equal_approx(game.player.yaw,1.1),"右手看方向時不可被車輛自動回正")
	print("TOUCH_CAMERA_PASS: ownership, multitouch, jump rejection, release, orientation, focus, vehicle")
	quit()
