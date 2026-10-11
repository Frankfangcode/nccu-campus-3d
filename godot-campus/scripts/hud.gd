extends CanvasLayer
const MapView = preload("res://scripts/tactical_map.gd")
const Touch = preload("res://scripts/touch_controls.gd")
var game: Node3D
var root: Control
var mission: Label
var place: Label
var prompt: Label
var notification: Label
var stamina: ColorRect
var minimap: Control
var menu: PanelContainer
var dialogue: PanelContainer
var speaker: Label
var words: Label
var dialogue_lines: Array = []
var map_large := false
var note_time := 0.0
var touch: Control
var title: Label
var sub: Label
var keys: Label
var mission_panel: PanelContainer
var route_label: Label
var speed_label: Label
var map_button: Button
var pause_button: Button
var atlas: Control
var atlas_panel: PanelContainer
var atlas_root: Control
var atlas_title: Label
var atlas_close: Button
var atlas_list: VBoxContainer
var atlas_scroll: ScrollContainer
var atlas_search: LineEdit
var atlas_filters: HBoxContainer
var atlas_tools: HBoxContainer
var redraw_clock := 0.0

func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box

func label(text: String, font_size: int = 18, color: Color = Color("e7e9e2")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

func panel(pos: Vector2, dimensions: Vector2) -> PanelContainer:
	var node := PanelContainer.new()
	node.position = pos
	node.custom_minimum_size = dimensions
	node.add_theme_stylebox_override("panel", style(Color(0.035, 0.052, 0.06, 0.91), Color(0.8, 0.72, 0.5, 0.25)))
	root.add_child(node)
	return node

func button(text: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 52
	node.add_theme_stylebox_override("normal", style(Color("202d31"), Color("42504d")))
	node.add_theme_stylebox_override("hover", style(Color("435147"), Color("e4c47c")))
	node.add_theme_stylebox_override("pressed", style(Color("596147")))
	node.pressed.connect(callback)
	return node

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font = load("res://assets/fonts/NotoSansTC-Game.ttf" if OS.has_feature("web") else "res://assets/fonts/NotoSansTC.ttf")
	font.variation_opentype = {"wght": 500.0}
	font.variation_embolden = 0.6
	theme.default_font = font
	theme.default_font_size = 17
	theme.set_stylebox("panel", "Panel", style(Color("152429"), Color("4a5954")))
	root.theme = theme
	add_child(root)
	title = label("N C C U   /   G A I A", 15, Color("ecd09a"))
	title.position = Vector2(38, 30)
	root.add_child(title)
	place = label("政大・指南路校門", 28)
	place.position = Vector2(36, 56)
	root.add_child(place)
	sub = label("TAIPEI, WENSHAN    /    16:42", 13, Color("bdcbc7"))
	sub.position = Vector2(38, 103)
	root.add_child(sub)
	mission_panel = panel(Vector2(1040, 30), Vector2(330, 110))
	var list := VBoxContainer.new()
	mission_panel.add_child(list)
	list.add_child(label("校 園 記 憶", 14, Color("ecc881")))
	mission = label("", 17)
	list.add_child(mission)
	minimap = MapView.new()
	minimap.game = game
	minimap.position = Vector2(38, 654)
	minimap.size = Vector2(270, 195)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minimap)
	stamina = ColorRect.new()
	stamina.position = Vector2(38, 858)
	stamina.size = Vector2(270, 5)
	stamina.color = Color("e3c584")
	stamina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stamina)
	keys = label("WASD 移動   SHIFT 跑步   SPACE 跳躍   E 互動   M 地圖   ESC 選單", 14, Color("d0d6cd"))
	keys.position = Vector2(700, 849)
	root.add_child(keys)
	prompt = label("", 20, Color("fff2d3"))
	prompt.position = Vector2(430, 742)
	prompt.size.x = 580
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt)
	notification = label("", 20, Color("efd29a"))
	notification.position = Vector2(410, 165)
	notification.size.x = 620
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(notification)
	dialogue = panel(Vector2(365, 610), Vector2(710, 180))
	var dl := VBoxContainer.new()
	dialogue.add_child(dl)
	speaker = label("", 17, Color("edc87c"))
	dl.add_child(speaker)
	words = label("", 21)
	words.custom_minimum_size = Vector2(0, 70)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_child(words)
	dl.add_child(button("繼續   [ E / ENTER ]", advance_dialogue))
	dialogue.hide()
	menu = panel(Vector2(90, 245), Vector2(440, 420))
	var ml := VBoxContainer.new()
	ml.add_theme_constant_override("separation", 16)
	menu.add_child(ml)
	ml.add_child(label("蓋 亞 造 界", 44))
	ml.add_child(label("政大校園  /  自由探索", 20, Color("e7c986")))
	ml.add_child(label("沿著午後的林蔭大道，\n找回屬於這座校園的三段故事。", 18))
	ml.add_child(button("進入校園 / 繼續探索", func(): game.set_playing(true)))
	ml.add_child(button("回到校門", func(): game.return_to_gate(); game.set_playing(true)))
	ml.add_child(label("進度自動儲存 · Godot 3D Edition", 13, Color("9aaaa6")))
	route_label = label("",16,Color("d7afff"))
	route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(route_label)
	speed_label = label("",22,Color("f3ddac"))
	root.add_child(speed_label)
	map_button = button("地圖  M",toggle_map)
	root.add_child(map_button)
	pause_button = button("選單",func(): game.set_playing(not game.playing))
	root.add_child(pause_button)
	build_atlas()
	if game.mobile:
		touch = Touch.new()
		touch.game = game
		root.add_child(touch)
	root.resized.connect(layout)
	layout.call_deferred()

func make_touch_controls() -> void:
	for spec in [["↑", Vector2(125, 480), Vector2(0,-1)], ["↓",Vector2(125,580),Vector2(0,1)], ["←",Vector2(40,580),Vector2(-1,0)], ["→",Vector2(210,580),Vector2(1,0)]]:
		var b := button(spec[0], func(): pass)
		b.position = spec[1]
		b.size = Vector2(80, 80)
		b.button_down.connect(func(): game.player.touch_move = spec[2])
		b.button_up.connect(func(): game.player.touch_move = Vector2.ZERO)
		root.add_child(b)
	var interact := button("互動", func(): game.interact())
	interact.position = Vector2(1270, 670)
	interact.size = Vector2(110, 90)
	root.add_child(interact)

func show_dialogue(name_text: String, lines: Array) -> void:
	dialogue_lines = lines.duplicate()
	speaker.text = name_text
	game.player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue.show()
	advance_dialogue()

func advance_dialogue() -> void:
	if dialogue_lines.is_empty():
		dialogue.hide()
		game.set_playing(true)
		return
	words.text = str(dialogue_lines.pop_front())

func toast(text: String) -> void:
	notification.text = text
	note_time = 5.0

func toggle_map() -> void:
	if dialogue.visible or menu.visible:
		return
	map_large = not map_large
	atlas_root.visible = map_large
	game.player.enabled = not map_large
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_large or game.mobile else Input.MOUSE_MODE_CAPTURED
	if touch:
		touch.reset()
	if map_large:
		fill_destinations()
		atlas.queue_redraw()

func _process(delta: float) -> void:
	stamina.size.x = minimap.size.x * game.player.stamina / 100.0
	mission.text = "故事碎片  %d / 3\n%s" % [game.collected.size(), "前往四維堂，向校長分享" if game.collected.size() == 3 else "尋找地圖上的金色標記"]
	if game.completed:
		mission.text = "✓ 校園記憶已完成\n自由探索，留下你的故事"
	place.text = "四維堂・大禮堂" if game.player.position.x > 250 else ("政大・醉夢溪畔" if game.player.position.z < -120 else "政大・林蔭大道" if game.player.position.z < -15 else "政大・指南路校門")
	note_time -= delta
	notification.visible = note_time > 0
	minimap.queue_redraw()
	var nav: Node = game.navigation
	route_label.text = "自由探索 · 已發現 %d 個地點" % nav.discovered.size() if nav.destination_name.is_empty() else "%s\n%s" % [nav.destination_name,("沿紫色路線  %d m" % nav.distance) if nav.route_available else "此處無可用步行路線，請另選附近地點"]
	speed_label.text = "%02d  km/h" % (absf(game.car_speed)*3.6) if game.player.driving else ""
	if touch:
		touch.visible = game.playing and not dialogue.visible and not map_large
		if not touch.visible and (touch.move_id!=-1 or touch.look_id!=-1):
			touch.reset()
	redraw_clock += delta
	if redraw_clock>0.15:
		redraw_clock = 0
		if map_large:
			atlas.queue_redraw()
			atlas_title.text = "政大校園  /  探索 %d / 23" % nav.discovered.size()

func build_atlas() -> void:
	atlas_root = Control.new()
	atlas_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(atlas_root)
	var background := ColorRect.new()
	background.color = Color(0.025,0.04,0.065,0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atlas_root.add_child(background)
	atlas_title = label("政 大 校 園  /  自 由 探 索",24,Color("f0e7d1"))
	atlas_root.add_child(atlas_title)
	atlas_close = button("返回遊戲 ×",toggle_map)
	atlas_root.add_child(atlas_close)
	atlas = MapView.new()
	atlas.game = game
	atlas.expanded = true
	atlas.selected.connect(func(name_text: String): toast("導航目的地："+name_text); fill_destinations())
	atlas_root.add_child(atlas)
	atlas_search = LineEdit.new()
	atlas_search.placeholder_text = "搜尋地點、人物、任務…"
	atlas_search.text_changed.connect(func(_value): fill_destinations())
	atlas_root.add_child(atlas_search)
	atlas_filters = HBoxContainer.new()
	for spec in [["全部","all"],["任務","story"],["地點","place"],["人物","person"]]:
		var value: String = spec[1]
		var b := button(spec[0],func(): atlas.filter=value; fill_destinations(); atlas.queue_redraw())
		b.custom_minimum_size = Vector2(56,44)
		atlas_filters.add_child(b)
	atlas_root.add_child(atlas_filters)
	atlas_scroll = ScrollContainer.new()
	atlas_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	atlas_list = VBoxContainer.new()
	atlas_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atlas_scroll.add_child(atlas_list)
	atlas_root.add_child(atlas_scroll)
	atlas_tools = HBoxContainer.new()
	for spec in [["＋",func(): atlas.zoom_by(1.3)],["－",func(): atlas.zoom_by(1.0/1.3)],["定位",func(): atlas.center=Vector2(game.player.position.x,game.player.position.z); atlas.queue_redraw()],["追蹤任務",func(): game.navigation.auto_destination(); fill_destinations()]]:
		atlas_tools.add_child(button(spec[0],spec[1]))
	atlas_root.add_child(atlas_tools)
	atlas_root.hide()

func fill_destinations() -> void:
	for node in atlas_list.get_children():
		atlas_list.remove_child(node)
		node.queue_free()
	var count := 0
	for poi in game.navigation.pois:
		if atlas.filter!="all" and poi.kind!=atlas.filter:
			continue
		if not atlas_search.text.is_empty() and not str(poi.name).contains(atlas_search.text):
			continue
		var destination: Vector3 = poi.pos
		var name_text: String = poi.name
		var done: bool = poi.kind=="story" and poi.index in game.collected
		var prefix := "✓ " if done else ("◆ " if poi.kind=="story" else "● ")
		var b := button(prefix+name_text,func(): game.navigation.select_destination(destination,name_text); atlas.center=Vector2(destination.x,destination.z) if destination.x<250 else Vector2(0,-75); atlas.queue_redraw(); toast("已標記："+name_text))
		b.clip_text = true
		b.tooltip_text = name_text
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 46
		atlas_list.add_child(b)
		count += 1
	if count==0:
		atlas_list.add_child(label("找不到符合的地點",16))
	atlas_title.text = "政大校園  /  探索 %d / 23" % game.navigation.discovered.size()

func layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var compact: bool = game.mobile
	var portrait := s.x<s.y
	title.position = Vector2(24,18)
	place.position = Vector2(22,40)
	place.add_theme_font_size_override("font_size",22 if compact else 28)
	sub.position = Vector2(24,80)
	sub.visible = not compact
	mission_panel.position = Vector2(s.x-350,20)
	mission_panel.visible = not portrait
	map_button.position = Vector2(s.x-202,142 if not compact else 136)
	map_button.size = Vector2(110,48)
	pause_button.position = Vector2(s.x-86,142 if not compact else 136)
	pause_button.size = Vector2(66,48)
	if portrait:
		map_button.position.y = 82
		pause_button.position.y = 82
	minimap.position = Vector2(24,s.y-370 if compact else s.y-245)
	minimap.size = Vector2(160,110) if compact else Vector2(270,175)
	if portrait:
		minimap.position = Vector2(24,150)
	stamina.position = minimap.position+Vector2(0,minimap.size.y+5)
	stamina.size.y = 4
	route_label.position = minimap.position+Vector2(0,minimap.size.y+14)
	route_label.size = Vector2(260 if not compact else 230,60)
	keys.visible = not compact
	keys.position = Vector2(maxf(330,s.x-710),s.y-42)
	keys.add_theme_color_override("font_shadow_color",Color.BLACK)
	keys.add_theme_constant_override("shadow_offset_x",1)
	keys.add_theme_constant_override("shadow_offset_y",2)
	prompt.position = Vector2(s.x*0.5-230,s.y-100 if not compact else s.y-70)
	prompt.size.x = 460
	if portrait:
		prompt.position = Vector2(24,s.y-270)
		prompt.size.x = s.x-48
	notification.position = Vector2(24,118 if not portrait else 350)
	notification.size.x = s.x-48
	menu.custom_minimum_size = Vector2(minf(440,s.x-48),0)
	menu.size.x = minf(440,s.x-48)
	menu.position = Vector2(24,maxf(110,(s.y-430)/2))
	dialogue.custom_minimum_size.x = minf(710,s.x-48)
	dialogue.size.x = minf(710,s.x-48)
	dialogue.position = Vector2((s.x-dialogue.size.x)/2,s.y-230)
	speed_label.position = Vector2(s.x-190,s.y-290 if compact else s.y-115)
	atlas_title.position = Vector2(24,22)
	atlas_close.position = Vector2(s.x-164,16)
	atlas_close.size = Vector2(140,48)
	var sidebar := 290.0
	atlas.position = Vector2(24,82)
	atlas.size = Vector2(s.x-sidebar-58,s.y-164)
	atlas_search.position = Vector2(s.x-sidebar-16,82)
	atlas_search.size = Vector2(sidebar-8,44)
	atlas_filters.position = Vector2(s.x-sidebar-16,136)
	atlas_scroll.position = Vector2(s.x-sidebar-16,194)
	atlas_scroll.size = Vector2(sidebar-8,s.y-215)
	atlas_tools.position = Vector2(24,s.y-68)
	if portrait:
		atlas_title.add_theme_font_size_override("font_size",18)
		atlas.size = Vector2(s.x-48,s.y*0.42)
		atlas_tools.position = Vector2(24,atlas.position.y+atlas.size.y+12)
		atlas_search.position = Vector2(24,atlas_tools.position.y+64)
		atlas_search.size.x = s.x-48
		atlas_filters.position = Vector2(24,atlas_search.position.y+52)
		atlas_scroll.position = Vector2(24,atlas_filters.position.y+58)
		atlas_scroll.size = Vector2(s.x-48,s.y-atlas_scroll.position.y-16)
	if touch:
		touch.layout(s)
