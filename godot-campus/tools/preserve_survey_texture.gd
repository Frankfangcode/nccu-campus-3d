extends SceneTree
## 只更換照片街區的外部貼圖參照，不重建或移動使用者的建築。
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var count := 0
	for filename in DirAccess.get_files_at("res://assets/architecture_meshes"):
		if not filename.ends_with(".res") or not "leaf" in filename:
			continue
		var path := "res://assets/architecture_meshes/"+filename
		var resource: MultiMesh = load(path)
		assert(resource.buffer.size()==resource.instance_count*12)
		var material: StandardMaterial3D = resource.mesh.material
		material.albedo_texture = load("res://assets/textures/survey-leaves.png")
		assert(ResourceSaver.save(resource,path,ResourceSaver.FLAG_COMPRESS)==OK)
		count += 1
	print("SURVEY_TEXTURE_PRESERVED ",count)
	quit()
