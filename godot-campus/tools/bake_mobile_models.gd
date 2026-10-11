extends SceneTree
func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	for name in ["student","student_female"]:
		var scene: Node3D = load("res://assets/models/"+name+".glb").instantiate()
		root.add_child(scene)
		for node in scene.find_children("*","MeshInstance3D",true,false):
			var source: ArrayMesh = node.mesh
			var compact := ArrayMesh.new()
			for surface in range(source.get_surface_count()):
				var raw := RenderingServer.mesh_get_surface(source.get_rid(),surface)
				var indices: PackedInt32Array = source.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
				var stride := 4 if raw.vertex_count>65536 else 2
				for lod in raw.get("lods",[]):
					var bytes: PackedByteArray = lod.index_data
					if bytes.size()/stride<90000:
						indices.resize(bytes.size()/stride)
						for j in range(indices.size()):
							indices[j] = bytes.decode_u32(j*4) if stride==4 else bytes.decode_u16(j*2)
						break
				var remap := {}
				var originals := PackedInt32Array()
				for j in range(indices.size()):
					var old := indices[j]
					if not remap.has(old):
						remap[old] = originals.size()
						originals.append(old)
					indices[j] = remap[old]
				var arrays := source.surface_get_arrays(surface)
				var vertex_count: int = arrays[0].size()
				for channel in range(Mesh.ARRAY_INDEX):
					if arrays[channel]==null or arrays[channel].is_empty():
						continue
					var old_array = arrays[channel]
					var count: int = old_array.size()/vertex_count
					var next_array = old_array.duplicate()
					next_array.resize(originals.size()*count)
					for v in range(originals.size()):
						for component in range(count):
							next_array[v*count+component] = old_array[originals[v]*count+component]
					arrays[channel] = next_array
				arrays[Mesh.ARRAY_INDEX] = indices
				compact.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				compact.surface_set_material(surface,source.surface_get_material(surface))
				print(name," reduced ",raw.index_count/3," -> ",indices.size()/3," triangles, ",originals.size()," vertices")
			node.mesh = compact
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(scene,state)
		assert(error==OK)
		error = document.write_to_filesystem(state,"res://assets/models/"+name+"_mobile.glb")
		assert(error==OK)
		scene.free()
	quit()
