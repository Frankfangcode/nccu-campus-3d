extends SceneTree
## Saves the same geometry used in the game as editable, editor-visible nodes.
class BuildContext extends Node3D:
	var data := {"colliders":[],"lots":[]}

func _initialize() -> void:
	run.call_deferred()

func own_children(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner = scene
		own_children(child,scene)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Run this bake with a rendering device, without --headless.")
		quit(1)
		return
	var context := BuildContext.new()
	root.add_child(context)
	var architecture = load("res://scripts/architecture_detail.gd").new()
	architecture.name = "PhotoReferencedArchitecture"
	context.add_child(architecture)
	architecture.initialize(context)
	await process_frame
	await RenderingServer.frame_post_draw
	var instances := 0
	DirAccess.make_dir_recursive_absolute("res://assets/architecture_meshes")
	for visual in architecture.find_children("*","MultiMeshInstance3D",true,false):
		if visual.multimesh.buffer.size() != visual.multimesh.instance_count*12:
			printerr("Baking requires a rendering device: run without --headless so instance transforms are serialized.")
			quit(1)
			return
		instances += visual.multimesh.instance_count
		# External resources avoid Godot #106950 when parent and child scenes are open.
		var mesh_path := "res://assets/architecture_meshes/"+str(visual.name)+".res"
		assert(ResourceSaver.save(visual.multimesh,mesh_path,ResourceSaver.FLAG_COMPRESS) == OK)
		visual.multimesh.take_over_path(mesh_path)
	for label in architecture.find_children("*","Label3D",true,false):
		label.font = load("res://assets/fonts/NotoSansTC-Game.ttf")
	own_children(architecture,architecture)
	architecture.use_baked_visuals = true
	var packed := PackedScene.new()
	assert(packed.pack(architecture) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/photo_architecture.tscn") == OK)
	print("BAKED_ARCHITECTURE_SCENE: ",architecture.get_child_count()," districts, ",instances," instances, ",architecture.find_children("*","CollisionShape3D",true,false).size()," colliders")
	quit()
