extends SceneTree
## 驗證新版事件分支、暫停控制、雨天保護、問答成敗與信函存檔。
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/campus.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://web_events_test_save.json"
	game.mobile = true
	game.set_playing(true)
	game.have_letter = false
	var events = game.web_events
	events.set_process(false)
	assert(events.lions.size()==2 and events.principal.get_child_count()>0)
	events.start_rain()
	game.player.position = Vector3(0,0,14)
	events._process(1.0)
	assert(is_equal_approx(events.rain_hp,98.7),"戶外雨天扣體力")
	game.player.position.x = 300
	events._process(1.0)
	assert(is_equal_approx(events.rain_hp,98.7),"室內避雨")
	game.player.position.x = 0
	events.take_umbrella()
	events._process(1.0)
	assert(is_equal_approx(events.rain_hp,98.7) and events.held_umbrella.visible,"雨傘保護")
	events.cop_talk()
	assert(events.modal and not game.player.enabled)
	events.close_modal()
	assert(game.player.enabled,"對話結束恢復操作")
	events.start_battle()
	events.close_modal()
	events.battle_turn(3)
	assert(not events.holding,"逃跑遺失雨傘")
	events.close_modal()
	events.start_quiz()
	events.close_modal()
	var wrong: int = (int(events.questions[0].answer)+1)%events.questions[0].options.size()
	events.answer_question(wrong)
	assert(events.quiz_index==0 and events.retry_left>0 and not game.have_letter,"答錯立即結束")
	events.close_modal()
	events.start_quiz()
	for i in range(events.questions.size()):
		events.close_modal()
		events.answer_question(int(events.questions[i].answer))
	assert(game.have_letter,"全對取得信函")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	assert(saved.have_letter,"信函獎勵持久化")
	events.close_modal()
	events.stop_rain()
	assert(not events.raining and not events.ground_umbrella.visible and not events.cop_chasing)
	if "--snapshot" in OS.get_cmdline_user_args():
		game.player.position = Vector3(-46,0,-76)
		events.start_rain()
		events.take_umbrella()
		events.cop_delay = -1
		events._process(1.0)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = Vector3(-60,7,-67)
		camera.look_at(Vector3(-46,2,-82))
		camera.current = true
		for i in range(15): await process_frame
		root.get_texture().get_image().save_png("res://artifacts/web-v124-rain.png")
		events.start_quiz()
		for i in range(3): await process_frame
		root.get_texture().get_image().save_png("res://artifacts/web-v124-quiz.png")
	DirAccess.remove_absolute(game.save_path)
	print("WEB_EVENTS_PASS: rain, shelter, umbrella, modal controls, battle escape, quiz fail/pass, saved letter, cleanup")
	quit()
