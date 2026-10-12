extends Node3D
## Photo-informed exteriors. Positions follow the existing stylized game map.
## Boxes are instanced per material and district, keeping mobile draw calls low.
var game: Node3D
var batches: Dictionary = {}
var materials: Dictionary = {}
var origin := Vector3.ZERO
var district := ""
var built: Array[String] = []

func _ready() -> void:
	make_materials()
	law_college()
	jing_tang()
	journalism()
	social_science()
	street()
	flush()
	print("ARCHITECTURE_DETAIL ready ", built.size(), " landmarks; ", batches.size(), " batches")

func make_materials() -> void:
	var palette := {"wall":"555e60","trim":"dadcd4","fins":"c6a074","frame":"293b41","glass":"536b70","dark":"253236","stone":"a9aaa0","road":"42484b","paving":"a0a69d","brick":"896a56","cream":"beb7a2","green":"4a6952","yellow":"dbb963","white":"e2e1d4","red":"984f42"}
	for key in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(palette[key])
		material.roughness = 0.27 if key == "glass" else 0.88
		material.metallic = 0.28 if key == "glass" else 0.0
		if key in ["wall", "stone", "paving", "cream"]:
			if key in ["stone", "paving"]:
				material.albedo_texture = load("res://assets/textures/pavement_02_albedo.jpg")
			material.normal_texture = load("res://assets/textures/pavement_02_normal.jpg")
			material.normal_enabled = true
			material.normal_scale = 0.25
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_scale = Vector3.ONE * 0.5
		materials[key] = material

func box(key: String, at: Vector3, dimensions: Vector3) -> void:
	var batch := district+":"+key
	if not batches.has(batch):
		batches[batch] = []
	batches[batch].append(Transform3D(Basis.from_scale(dimensions), origin+at))

func solid(at: Vector3, dimensions: Vector3) -> void:
	var p := origin+at
	var shape := BoxShape3D.new()
	shape.size = dimensions
	game.solid(shape,p)
	# Navigation and physics consume the same obstacle footprint.
	if dimensions.y > 0.5:
		game.data.colliders.append({"x0":p.x-dimensions.x/2,"x1":p.x+dimensions.x/2,"z0":p.z-dimensions.z/2,"z1":p.z+dimensions.z/2,"top":p.y+dimensions.y/2})

func sign_text(caption: String, at: Vector3, pixels: float, color: Color = Color("eee5cd"), angle: float = 0.0) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = load("res://assets/fonts/NotoSansTC-Game.ttf" if OS.has_feature("web") else "res://assets/fonts/NotoSansTC.ttf")
	label.font_size = 64
	label.pixel_size = pixels
	label.position = origin+at
	label.rotation.y = angle
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	label.visibility_range_end = 110
	add_child(label)

func window_front(x: float, y: float, z: float, width: float, height: float) -> void:
	box("frame",Vector3(x,y,z),Vector3(width+0.16,height+0.16,0.16))
	box("glass",Vector3(x,y,z+0.10),Vector3(width,height,0.045))
	box("frame",Vector3(x,y,z+0.15),Vector3(0.055,height,0.055))
	box("frame",Vector3(x,y+height*0.12,z+0.15),Vector3(width,0.05,0.055))
	box("trim",Vector3(x,y-height/2-0.10,z+0.18),Vector3(width+0.23,0.10,0.38))

func law_college() -> void:
	district = "LawCollege"
	origin = Vector3(-200,0,-66)
	built.append("法學院")
	# Approximate proportions from the user's completed-building photographs.
	# The supplied architectural rendering is not treated as as-built evidence.
	box("paving",Vector3(0,0.045,4),Vector3(44,0.09,34))
	box("wall",Vector3(0,15,-1.0),Vector3(35,24,19))
	box("dark",Vector3(0,1.5,-3),Vector3(35,3,15))
	solid(Vector3(0,13.5,-1),Vector3(35,27,19))
	box("trim",Vector3(0,27.1,-1),Vector3(38,0.55,22))
	box("wall",Vector3(-11,28.1,-4),Vector3(7,1.8,7))
	# Double-height glazed podium and recessed entrance.
	box("dark",Vector3(0,1.6,9.0),Vector3(23,3.2,0.5))
	for x in [-15.4,-10.2,-5.1,5.1,10.2,15.4]:
		box("wall",Vector3(x,1.6,10.2),Vector3(0.55,3.2,2.4))
		solid(Vector3(x,1.6,10.2),Vector3(0.55,3.2,2.4))
	for x in range(-15,16):
		window_front(x,5.5,8.65,0.83,3.5)
	box("trim",Vector3(0,3.15,9.45),Vector3(36,0.45,2.4))
	box("trim",Vector3(0,7.8,9.1),Vector3(36,0.40,1.8))
	box("trim",Vector3(17.7,5.45,9.1),Vector3(0.6,4.8,1.8))
	# Five upper rows; narrow mullions and protruding warm-colored fins.
	for row in range(5):
		var y := 10.0+row*3.3
		for col in range(14):
			var x := -15.6+col*2.4
			window_front(x,y,8.62,1.15,2.1)
			box("fins",Vector3(x-0.88,y,9.0),Vector3(0.20,3.25,0.9))
		box("trim",Vector3(0,y-1.6,8.97),Vector3(35.7,0.13,1.1))
	# A dense screen across the left central bay.
	for i in range(20):
		box("fins",Vector3(-15.8+i*0.60,11.4,9.65),Vector3(0.14,6.25,0.8))
	# Framed side balconies and the College of LAW identity.
	for side in [-1.0,1.0]:
		box("trim",Vector3(side*17.8,15.0,-6.0),Vector3(0.55,21,0.6))
		box("trim",Vector3(side*17.8,15.0,0.0),Vector3(0.55,21,0.6))
		box("trim",Vector3(side*17.8,25.3,-3),Vector3(0.55,0.55,6.6))
		for row in range(6):
			var y := 5.5+row*3.3
			box("glass",Vector3(side*17.56,y,-3),Vector3(0.12,2.5,5.3))
			box("frame",Vector3(side*17.7,y,-3),Vector3(0.15,2.6,0.06))
			if row in [1,3]:
				box("fins",Vector3(side*18.05,y-0.7,-3),Vector3(0.85,1.05,5.2))
		for col in range(3):
			for row in range(7):
				box("glass",Vector3(side*17.57,3.2+row*3.25,2.0+col*2.0),Vector3(0.08,1.85,0.70))
		sign_text("College of\nLAW",Vector3(side*18.0,26.1,-3),0.020,Color.WHITE,side*PI/2)
	sign_text("College of Law",Vector3(0,3.25,10.69),0.012)
	box("stone",Vector3(10,1.05,14.4),Vector3(7,2.1,0.65))
	solid(Vector3(10,1.05,14.4),Vector3(7,2.1,0.65))
	sign_text("法 學 院",Vector3(10,1.25,14.75),0.022,Color("685843"))
	for i in range(3):
		box("stone",Vector3(0,0.09+i*0.07,11.6-i*0.5),Vector3(9,0.18+i*0.14,0.5))
	# Low planted beds and seating, kept outside the approach path.
	for x in [-14.0,15.0]:
		box("stone",Vector3(x,0.32,17.5),Vector3(6,0.64,1.8))
		solid(Vector3(x,0.32,17.5),Vector3(6,0.64,1.8))
		box("green",Vector3(x,0.72,17.5),Vector3(5.8,0.45,1.6))
		box("fins",Vector3(x,0.55,15.4),Vector3(4.0,0.14,0.55))
	game.data.lots.append({"name":"法學院","x":-200,"z":-67,"w":35,"d":19})

func jing_tang() -> void:
	district = "JingTang"
	origin = Vector3(-160,0,-118)
	built.append("井塘樓")
	# Reference da2725ca1c7a: four floors, shallow concave facade and white ribs.
	for col in range(11):
		var x := -10.0+col*2.0
		var curve := 1.8*pow(x/10.0,2)
		box("trim",Vector3(x,6.5,curve-0.9),Vector3(2.02,13,12.0))
		box("stone",Vector3(x,13.05,curve-0.9),Vector3(2.05,0.25,12.5))
		box("trim",Vector3(x-0.89,6.5,curve+5.32),Vector3(0.16,13,0.45))
		for row in range(4):
			window_front(x,1.6+row*3.1,curve+5.2,1.25,1.55)
	solid(Vector3(0,6.5,0),Vector3(22,13,14))
	box("dark",Vector3(0,1.45,5.32),Vector3(2.8,2.9,0.12))
	box("stone",Vector3(0,3.10,6.1),Vector3(6.4,0.22,3.0))
	for x in [-2.6,2.6]:
		box("trim",Vector3(x,1.55,7.1),Vector3(0.18,3.1,0.18))
	sign_text("井 塘 樓",Vector3(0,3.45,7.7),0.011,Color("66544c"))

func journalism() -> void:
	district = "Journalism"
	origin = Vector3(112,0,-25)
	built.append("新聞館")
	# Reference 3399b293f617: pale vertical fins and terracotta insets.
	box("cream",Vector3(0,4.5,0),Vector3(20,9,8))
	solid(Vector3(0,4.5,0),Vector3(20,9,8))
	box("trim",Vector3(0,9.1,0),Vector3(20.4,0.25,8.4))
	for col in range(12):
		var x := -9.0+col*1.65
		window_front(x,2.1,4.07,1.10,2.0)
		window_front(x,5.8,4.07,1.10,3.0)
		box("trim",Vector3(x-0.76,6.2,4.4),Vector3(0.20,5.8,0.9))
		box("brick",Vector3(x-0.76,5.7,4.89),Vector3(0.20,2.6,0.10))
	box("brick",Vector3(0,3.5,4.5),Vector3(21,0.3,1.5))
	box("dark",Vector3(0,1.3,4.26),Vector3(3.0,2.6,0.15))
	sign_text("新 聞 館",Vector3(0,6.0,4.96),0.016,Color("6f5441"))

func social_science() -> void:
	district = "SocialScience"
	origin = Vector3(-202,0,-114)
	built.append("社資中心")
	# Reference 9db890983ead: long dark facade, four window bands, pale base.
	box("wall",Vector3(0,6.5,0),Vector3(24,13,18))
	solid(Vector3(0,6.5,0),Vector3(24,13,18))
	box("trim",Vector3(0,2.9,9.16),Vector3(24,0.42,0.35))
	for row in range(4):
		for col in range(15):
			window_front(-11.0+col*1.57,1.5+row*3.0,9.12,1.20,1.7)
	box("trim",Vector3(0,3.0,10.0),Vector3(7,0.35,3))
	for x in [-2.8,2.8]:
		box("brick",Vector3(x,1.5,10.5),Vector3(0.4,3,0.4))
	box("dark",Vector3(0,1.3,9.28),Vector3(3.6,2.6,0.2))
	sign_text("社會科學資料中心",Vector3(0,3.45,11.52),0.011)

func street() -> void:
	district = "ZhinanStreet"
	origin = Vector3.ZERO
	built.append("指南路街廓")
	# An interpreted neighborhood streetscape, not a survey of individual shops.
	box("paving",Vector3(-1,0.035,53),Vector3(300,0.07,40))
	box("road",Vector3(-1,0.078,42),Vector3(300,0.055,14))
	for z in [41.65,42.35]:
		box("yellow",Vector3(-1,0.112,z),Vector3(299,0.016,0.12))
	for x in range(-145,145,6):
		box("white",Vector3(x,0.113,37),Vector3(2.5,0.015,0.12))
	for x in [-90,0,90]:
		for step in range(9):
			box("white",Vector3(x,0.115,35.8+step*1.5),Vector3(4,0.018,0.7))
	for i in range(16):
		var x := -136.0+i*18.0
		var height := 12.0+float((i*7)%4)*3.0
		var tone: String = ["cream","wall","brick"][i%3]
		box(tone,Vector3(x,height/2,63),Vector3(16,height,17))
		solid(Vector3(x,height/2,63),Vector3(16,height,17))
		box("dark",Vector3(x,1.8,54.38),Vector3(14,3.5,0.15))
		# Storefront bays, recessed doors and metal roller shutters.
		for bay in range(3):
			var bx := x-4.5+bay*4.5
			box("frame",Vector3(bx,1.2,54.14),Vector3(4.1,2.35,0.15))
			if (i+bay)%3 == 0:
				box("stone",Vector3(bx,1.2,54.04),Vector3(3.95,2.25,0.1))
				for slat in range(12):
					box("frame",Vector3(bx,0.2+slat*0.18,53.97),Vector3(3.95,0.023,0.04))
			else:
				box("glass",Vector3(bx,1.2,54.03),Vector3(3.9,2.2,0.08))
				box("frame",Vector3(bx,1.2,53.97),Vector3(0.06,2.2,0.06))
		box("trim",Vector3(x,3.8,53),Vector3(16.6,0.25,3.2))
		box("frame",Vector3(x-7.5,1.85,51.8),Vector3(0.30,3.7,0.30))
		box("frame",Vector3(x+7.5,1.85,51.8),Vector3(0.30,3.7,0.30))
		solid(Vector3(x-7.5,1.85,51.8),Vector3(0.30,3.7,0.30))
		solid(Vector3(x+7.5,1.85,51.8),Vector3(0.30,3.7,0.30))
		box(["green","red","fins"][i%3],Vector3(x,3.0,53.95),Vector3(13,1.0,0.22))
		sign_text(["書店","咖啡 · 輕食","日常食堂","文具 · 影印"][i%4],Vector3(x,3.05,53.78),0.011,Color("efe7d6"),PI)
		for row in range(int(height/3)-1):
			for col in range(4):
				var xx := x-5.4+col*3.6
				var yy := 5.3+row*3.0
				box("frame",Vector3(xx,yy,54.35),Vector3(2.3,1.8,0.16))
				box("glass",Vector3(xx,yy,54.23),Vector3(2.12,1.65,0.08))
				box("frame",Vector3(xx,yy,54.15),Vector3(0.065,1.65,0.06))
				box("frame",Vector3(xx,yy+0.35,54.15),Vector3(2.12,0.055,0.06))
				box("trim",Vector3(xx,yy-0.9,53.95),Vector3(2.5,0.12,0.65))
				if (col+row+i)%3 == 0:
					box("stone",Vector3(xx+0.65,yy-1.25,53.8),Vector3(0.95,0.55,0.55))
					box("frame",Vector3(xx+0.65,yy-1.25,53.49),Vector3(0.60,0.38,0.035))
		box("trim",Vector3(x,height+0.15,63),Vector3(16.5,0.3,17.5))
		box("stone",Vector3(x+3,height+0.8,64),Vector3(3,1.3,2.2))
		game.data.lots.append({"name":"指南路街廓 %02d"%(i+1),"x":x,"z":63,"w":16,"d":17,"approach_z":51.0,"map_only":true})
	# Bus shelter, public seating, paving joints, drain and curb edges.
	box("frame",Vector3(31,3.0,32.0),Vector3(9,0.18,2.4))
	for x in [27,35]:
		box("frame",Vector3(x,1.5,32.8),Vector3(0.12,3.0,0.12))
	box("glass",Vector3(31,1.7,33.0),Vector3(8.2,2.2,0.08))
	box("fins",Vector3(31,0.58,32.5),Vector3(6.8,0.15,0.48))
	sign_text("政大 · 指南路",Vector3(31,2.62,30.72),0.012)
	for z in [34.8,49.2]:
		box("stone",Vector3(-1,0.14,z),Vector3(300,0.28,0.24))
	for x in range(-144,149,18):
		box("frame",Vector3(x,0.13,49.5),Vector3(1.2,0.03,0.6))
		for stripe in range(5):
			box("stone",Vector3(x-0.45+stripe*0.22,0.15,49.5),Vector3(0.04,0.018,0.6))
	game.data.lots.append({"name":"指南路公車候車亭","x":31,"z":32,"w":9,"d":2.4})

func flush() -> void:
	for key in batches:
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = materials[key.get_slice(":",1)]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = batches[key].size()
		for i in range(multimesh.instance_count):
			multimesh.set_instance_transform(i,batches[key][i])
		var node := MultiMeshInstance3D.new()
		node.name = key.replace(":","_")
		node.multimesh = multimesh
		node.visibility_range_end = 290.0
		add_child(node)
