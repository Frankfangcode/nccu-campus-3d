extends SceneTree
func _initialize() -> void:
	inspect.call_deferred()
func inspect() -> void:
	for path in ["res://assets/models/student.glb", "res://assets/models/student_female.glb", "res://assets/models/campus.glb"]:
		var packed = load(path) as PackedScene
		if not packed:
			push_error("Missing: " + path)
			quit(1)
			return
		var model = packed.instantiate()
		root.add_child(model)
		var box := AABB()
		var first := true
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = node.global_transform * node.get_aabb()
			box = b if first else box.merge(b)
			first = false
			if path.ends_with("campus.glb") and b.end.y > 80:
				print("HIGH_MESH ", node.name, " ", b, " ", node.mesh.surface_get_material(0).resource_name)
		print(path, " bounds=", box)
		for animation in model.find_children("*", "AnimationPlayer", true, false):
			print("ANIMATIONS ", animation.get_path(), " ", animation.get_animation_list())
		model.queue_free()
	quit()
