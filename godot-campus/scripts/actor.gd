extends Node3D
## Shared skinned character with looping walk/run and a relaxed frozen walk pose.
var animation: AnimationPlayer
var current := ""
var umbrella_active := false
var skeleton: Skeleton3D
static var idle_cache: Dictionary = {}

func setup(female: bool = false) -> void:
	var path := "res://assets/models/student_female.glb" if female else "res://assets/models/student.glb"
	if OS.has_feature("web") or "--mobile-test" in OS.get_cmdline_user_args():
		path = path.replace(".glb","_mobile.glb")
	var model: Node3D = load(path).instantiate()
	add_child(model)
	for node in model.find_children("*", "Skeleton3D", true, false):
		skeleton = node
	process_priority = 100
	for node in model.find_children("*", "AnimationPlayer", true, false):
		animation = node
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.lod_bias = 0.35 if OS.has_feature("web") else 0.7
		mesh.visibility_range_end = 100.0
		mesh.visibility_range_end_margin = 15.0
	if animation:
		for name in animation.get_animation_list():
			animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
		if not idle_cache.has(path):
			idle_cache[path] = make_idle(animation.get_animation("walk"))
		var library := AnimationLibrary.new()
		library.add_animation("idle", idle_cache[path])
		animation.add_animation_library("campus", library)
		animation.play("campus/idle")
		animation.advance(0)

func _process(_delta: float) -> void:
	if umbrella_active and is_instance_valid(skeleton):
		var upper := skeleton.find_bone("RightArm")
		var lower := skeleton.find_bone("RightForeArm")
		if upper >= 0:
			skeleton.set_bone_pose_rotation(upper,Quaternion.from_euler(Vector3(-0.9,0,-0.4)))
		if lower >= 0:
			skeleton.set_bone_pose_rotation(lower,Quaternion.from_euler(Vector3(-1.1,0,0)))

func make_idle(walk: Animation) -> Animation:
	# Average a complete stride into a balanced standing pose, retaining relaxed arms.
	var idle := Animation.new()
	idle.length = 2.0
	idle.loop_mode = Animation.LOOP_LINEAR
	for track in range(walk.get_track_count()):
		var kind := walk.track_get_type(track)
		if kind not in [Animation.TYPE_ROTATION_3D, Animation.TYPE_POSITION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var output := idle.add_track(kind)
		idle.track_set_path(output, walk.track_get_path(track))
		if kind == Animation.TYPE_ROTATION_3D:
			var sum := Vector4.ZERO
			var reference := walk.rotation_track_interpolate(track, 0)
			for sample in range(16):
				var q := walk.rotation_track_interpolate(track, walk.length * sample / 16.0)
				var sign_value := -1.0 if reference.dot(q) < 0 else 1.0
				sum += Vector4(q.x,q.y,q.z,q.w) * sign_value
			var rotation_value := Quaternion(sum.x,sum.y,sum.z,sum.w).normalized()
			idle.rotation_track_insert_key(output, 0, rotation_value)
		elif kind == Animation.TYPE_POSITION_3D:
			var average := Vector3.ZERO
			for sample in range(16):
				average += walk.position_track_interpolate(track, walk.length * sample / 16.0) / 16.0
			idle.position_track_insert_key(output, 0, average)
		else:
			idle.scale_track_insert_key(output, 0, walk.scale_track_interpolate(track, 0))
	return idle

func animate(speed: float) -> void:
	if not animation:
		return
	var next := "idle" if speed < 0.15 else ("run" if speed > 4.0 else "walk")
	if next != current:
		current = next
		if next == "idle":
			animation.play("campus/idle", 0.22)
		else:
			animation.play(next, 0.2)
	if next != "idle":
		animation.speed_scale = clampf(speed / (5.5 if next == "run" else 2.0), 0.65, 1.5)
