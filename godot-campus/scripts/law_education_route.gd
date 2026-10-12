extends RefCounted
## October 12 walking survey: photos 059–102; downhill map is a topology reference.
## All dimensions are estimates in the existing game's meter-based coordinate frame.
var b: Node3D

func build(builder: Node3D) -> void:
	b = builder
	materials()
	swimming_pool()
	dormitory()
	kindergarten()
	dormitory_nine()
	jing_tang()
	b.social_science()
	landscape()

func materials() -> void:
	var colors := {"pink":"b89b91","rose":"ae7380","tile":"b9b8aa","roof":"596361","metal":"97a2a1","bark":"63584a","leaf":"526a37","leaflight":"6d7e44","leafdark":"364e32","lawn":"65784b","soil":"685d49","blue":"478ca6","playgreen":"75a93e","rubber":"696c64","carwhite":"d4d5cc","carblue":"30474f"}
	for key in colors:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(colors[key])
		material.roughness = 0.82
		if key == "metal":
			material.metallic = 0.65
			material.roughness = 0.4
		if key in ["leaf","leaflight","leafdark"]:
			material.albedo_texture = load("res://assets/models/campus_48.png")
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.4
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.albedo_color = Color("a8bc7c") if key == "leaflight" else Color("849964")
		if key in ["pink","tile","rose"]:
			var tiled := ShaderMaterial.new()
			tiled.shader = load("res://assets/shaders/campus_tile.gdshader")
			tiled.set_shader_parameter("tint",Color(colors[key]))
			tiled.set_shader_parameter("tile_size",0.105 if key == "pink" else 0.085)
			b.materials[key] = tiled
		else:
			b.materials[key] = material
	var lawn: StandardMaterial3D = b.materials.lawn
	lawn.albedo_color = Color("bac898")
	lawn.albedo_texture = load("res://assets/textures/aerial_grass_rock_albedo.jpg")
	lawn.uv1_triplanar = true
	lawn.uv1_world_triplanar = true
	lawn.uv1_scale = Vector3.ONE*0.14
	var brick: StandardMaterial3D = b.materials.brick
	brick.albedo_texture = load("res://assets/textures/brown_brick_02_albedo.jpg")
	brick.normal_texture = load("res://assets/textures/brown_brick_02_normal.jpg")
	brick.normal_enabled = true
	brick.normal_scale = 0.3
	brick.uv1_triplanar = true
	brick.uv1_world_triplanar = true
	brick.uv1_scale = Vector3.ONE*0.65
	var road: StandardMaterial3D = b.materials.road
	road.albedo_texture = load("res://assets/textures/asphalt_02_albedo.jpg")
	road.uv1_triplanar = true
	road.uv1_world_triplanar = true
	road.uv1_scale = Vector3.ONE*0.3

func mass(key: String, at: Vector3, size: Vector3) -> void:
	b.box(key,at,size)
	b.solid(at,size)

func rail(a: Vector3, z: Vector3, height: float = 1.0) -> void:
	b.beam("metal",a+Vector3.UP*height,z+Vector3.UP*height,0.055)
	b.beam("metal",a+Vector3.UP*height*0.45,z+Vector3.UP*height*0.45,0.035)
	var count := maxi(1,ceili(a.distance_to(z)/1.6))
	for i in range(count+1):
		var p := a.lerp(z,float(i)/count)
		b.beam("metal",p,p+Vector3.UP*height,0.045)

func steps(at: Vector3, width: float, rise: float, count: int, depth: float = 0.34) -> void:
	for i in range(count):
		b.box("stone",at+Vector3(0,rise*(i+1)/2,-depth*i),Vector3(width,rise*(i+1),depth+0.02))
	# One smooth collision ramp prevents the capsule snagging on individual risers.
	var length := depth*count
	var height := rise*count
	var angle := atan2(height,length)
	b.solid(at+Vector3(0,height/2-0.09,-length/2+depth/2),Vector3(width,0.18,sqrt(length*length+height*height)),Vector3(angle,0,0),true)

func ac(at: Vector3) -> void:
	b.box("stone",at,Vector3(0.95,0.55,0.48))
	b.box("dark",at+Vector3(0,0,0.25),Vector3(0.7,0.39,0.025))
	for i in range(6):
		b.box("metal",at+Vector3(0,-0.15+i*0.06,0.28),Vector3(0.73,0.018,0.025))
	b.beam("metal",at+Vector3(-0.4,-0.32,-0.3),at+Vector3(-0.4,-0.32,0.28),0.05)

func secondary_windows(width: float, depth: float, floors: int, spacing: float = 3.1) -> void:
	# Unphotographed rear portions use a restrained continuation of the window rhythm.
	for row in range(floors):
		var y := 1.8+row*spacing
		for col in range(int(width/3.0)):
			var x := -width/2+1.6+col*3.0
			b.box("frame",Vector3(x,y,-depth/2-0.07),Vector3(1.75,1.6,0.14))
			b.box("glass",Vector3(x,y,-depth/2-0.16),Vector3(1.56,1.4,0.04))
			b.box("stone",Vector3(x,y-0.85,-depth/2-0.23),Vector3(1.9,0.09,0.5))
		for side in [-1.0,1.0]:
			for col in range(int(depth/3.2)):
				var z := -depth/2+1.8+col*3.2
				b.box("frame",Vector3(side*(width/2+0.07),y,z),Vector3(0.14,1.6,1.6))
				b.box("glass",Vector3(side*(width/2+0.16),y,z),Vector3(0.035,1.4,1.4))

func swimming_pool() -> void:
	b.begin("SwimmingPool","游泳館",Vector3(-123,0,-120))
	b.landmark("游泳館",Vector3.ZERO,Vector2(38,20),Vector3(-9,0,15))
	# 071–080: long pink-tile hall, sloping metal shell and high glazed end wall.
	b.box("brick",Vector3(0,0.035,4),Vector3(47,0.07,32))
	mass("tile",Vector3(0,1.0,0),Vector3(38,2,20))
	mass("pink",Vector3(0,3.6,0),Vector3(38,3.2,20))
	b.box("roof",Vector3(0,7.2,-0.4),Vector3(39.2,0.26,22),Vector3(0.13,0,0))
	for x in range(-18,19,2):
		b.box("metal",Vector3(x,7.38,-0.4),Vector3(0.035,0.10,22),Vector3(0.13,0,0))
	# Clerestory at the front and full glass strips on both gable ends.
	for x in range(-17,18,2):
		b.window_front(x,6.1,10.03,1.7,1.45)
		b.box("stone",Vector3(x,4.30,10.12),Vector3(1.8,0.55,0.12))
	for side in [-1.0,1.0]:
		for col in range(8):
			var z := -8.7+col*2.45
			b.box("frame",Vector3(side*19.08,5.15,z),Vector3(0.15,3.4,2.35))
			b.box("glass",Vector3(side*19.18,5.15,z),Vector3(0.04,3.2,2.15))
			b.box("trim",Vector3(side*19.26,4.0,z),Vector3(0.20,0.13,2.42))
		b.box("trim",Vector3(side*19.45,4.25,0),Vector3(0.50,7.9,0.4),Vector3(0,0,side*-0.10))
	# Staircase / shallow entry canopy / accessible side ramp from photos 077–079.
	b.box("dark",Vector3(-9,2.0,10.17),Vector3(8.8,3.4,0.1))
	for x in [-11.5,-9,-6.5]:
		b.window_front(x,2.4,10.27,2.0,2.5)
	steps(Vector3(-9,0,14),11,0.14,7)
	b.box("tile",Vector3(-9,4.15,11.3),Vector3(13,0.35,3.2))
	for x in [-14.8,-3.2]:
		mass("tile",Vector3(x,2.0,12.25),Vector3(0.45,4.0,0.5))
	b.sign_text("游 泳 館",Vector3(-9,4.62,11.9),0.014,Color("544a41"))
	for x in [-15.7,-2.3]:
		rail(Vector3(x,0,14.5),Vector3(x,1.0,11.5))
	b.box("stone",Vector3(8,0.52,11.7),Vector3(14,0.2,1.8),Vector3(0,0,-0.065))
	b.solid(Vector3(8,0.52,11.7),Vector3(14,0.2,1.8),Vector3(0,0,-0.065),true)
	rail(Vector3(1,1.0,12.65),Vector3(15,0.1,12.65))
	for x in [1.0,15.0]:
		b.box("blue",Vector3(x,0.95,12.78),Vector3(0.5,0.55,0.04))
	# Front information panels and tiled expansion joints.
	for x in [0.0,11.0]:
		b.box("blue",Vector3(x,2.25,10.16),Vector3(4.0,2.5,0.05))
	for x in range(-18,19,4):
		b.box("stone",Vector3(x,2.0,10.19),Vector3(0.06,3.7,0.08))

func dormitory() -> void:
	b.begin("DormitoryCourtyard","莊敬宿舍與候車亭",Vector3(-111,0,-34),PI)
	b.landmark("莊敬內舍（1～3）",Vector3.ZERO,Vector2(39,17),Vector3(0,0,13))
	# 060–061, 084–085: gray residence block with irregular ochre vertical pipes.
	mass("wall",Vector3(0,10,0),Vector3(39,20,17))
	secondary_windows(39,17,6)
	b.box("stone",Vector3(0,20.1,0),Vector3(39.6,0.35,17.6))
	for row in range(6):
		for col in range(16):
			var x := -18.1+col*2.4
			var y := 1.9+row*3.15
			b.window_front(x,y,8.6,1.28,1.40)
			if (row+col)%3 == 0:
				ac(Vector3(x+0.2,y-0.92,8.9))
	for col in range(12):
		var x := -16.9+col*3.1
		var shift := -0.55 if col%2 == 0 else 0.5
		b.beam("fins",Vector3(x,0.4,9.0),Vector3(x+shift,8,9.2),0.14)
		b.beam("fins",Vector3(x+shift,8,9.2),Vector3(x,19.4,9.0),0.14)
		b.beam("fins",Vector3(x+0.6,0.4,9.0),Vector3(x+shift+0.6,19.4,9.0),0.09)
	b.sign_text("莊 敬 宿 舍",Vector3(0,3.5,8.96),0.012)
	# Walkable bus shelter and ATM kiosk at the street corner.
	b.box("cream",Vector3(-7,2.8,12.6),Vector3(19,0.20,3.2))
	for x in [-16,-10,-4,2]:
		mass("cream",Vector3(x,1.4,13.6),Vector3(0.14,2.8,0.14))
		b.box("glass",Vector3(x+1.2,1.5,11.2),Vector3(2.3,2.3,0.06))
	for x in [-12,-4]:
		b.box("fins",Vector3(x,0.5,12),Vector3(5,0.15,0.45))
	b.sign_text("法學院  LAW COLLEGE",Vector3(-7,2.6,14.24),0.009,Color("48514b"))
	mass("green",Vector3(14,1.4,11.2),Vector3(4.5,2.8,2.1))
	b.box("stone",Vector3(14,1.4,12.3),Vector3(3.9,2.3,0.10))
	b.box("dark",Vector3(14,1.4,12.38),Vector3(1.0,1.9,0.08))
	b.box("blue",Vector3(14,1.7,12.43),Vector3(0.65,0.4,0.03))
	b.sign_text("ATM",Vector3(14,2.48,12.46),0.014)

func kindergarten() -> void:
	b.begin("Kindergarten","實小附設幼兒園",Vector3(-163,0,-31),PI)
	b.landmark("實小附設幼兒園",Vector3.ZERO,Vector2(32,19),Vector3(0,0,27))
	# 087–090: pale pink tiled wings, rounded stair tower and rose entry balcony.
	mass("pink",Vector3(2,7.5,0),Vector3(27,15,18))
	secondary_windows(27,18,5,3.0)
	b.primitive("cylinder","pink",Vector3(-12,7.5,2),Vector3(10,15,14))
	b.solid(Vector3(-12,7.5,2),Vector3(8,15,12))
	for y in [3.0,6.0,9.0,12.0,14.9]:
		b.box("stone",Vector3(2,y,9.13),Vector3(27,0.28,0.2))
		for col in range(10):
			b.window_front(-8+col*2.2,y-1.4,9.1,1.95,1.4)
		# Ring courses around the cylindrical stair tower.
		for i in range(14):
			var angle := -PI/2+float(i)*PI/13
			b.box("stone",Vector3(-12+5.02*sin(angle),y,2+7.02*cos(angle)),Vector3(1.2,0.25,0.17),Vector3(0,angle,0))
	# Colorful geometric wall mural, interpreted from the user's photo.
	b.box("trim",Vector3(-12,7.0,9.08),Vector3(5.3,4.3,0.09))
	for entry in [[-1.2,0.8,"blue"],[1.1,0.9,"yellow"],[-1.1,-1,"fins"],[1.2,-0.8,"playgreen"]]:
		b.box(entry[2],Vector3(-12+entry[0],7+entry[1],9.16),Vector3(1.95,1.45,0.035),Vector3(0,0,0.12))
	b.primitive("cylinder","rose",Vector3(3,3.8,11.6),Vector3(11,0.8,7))
	for x in [-1.2,7.2]:
		b.primitive("cylinder","rose",Vector3(x,1.75,13.1),Vector3(0.6,3.5,0.6))
		b.solid(Vector3(x,1.75,13.1),Vector3(0.6,3.5,0.6))
	b.box("cream",Vector3(-3.5,3.05,10.8),Vector3(17,0.18,3))
	b.sign_text("政大實小附設幼兒園",Vector3(0,4.72,9.3),0.011,Color("3e4640"))
	b.box("paving",Vector3(1,0.05,17),Vector3(29,0.1,14))
	for x in range(-12,16,2):
		b.box("playgreen",Vector3(x,0.76,24),Vector3(0.06,1.4,0.08))
		b.box("blue",Vector3(x+0.9,0.3,24),Vector3(1.8,0.55,0.08))
	for y in [0.6,1.4]:
		b.box("playgreen",Vector3(1,y,24),Vector3(28,0.05,0.06))
	b.solid(Vector3(1,0.6,24),Vector3(28,1.2,0.12))
	# Playground behind the perimeter fence; no photographed people are reproduced.
	for x in [-8,-5]:
		b.beam("playgreen",Vector3(x,0,17),Vector3(x,2.4,19),0.10)
		b.beam("playgreen",Vector3(x,0,21),Vector3(x,2.4,19),0.10)
	b.beam("playgreen",Vector3(-8,2.4,19),Vector3(-5,2.4,19),0.12)
	for x in [-7.3,-5.7]:
		b.beam("metal",Vector3(x,2.4,19),Vector3(x,0.7,19),0.025)
	b.box("rubber",Vector3(-6.5,0.65,19),Vector3(1.7,0.08,0.4))
	b.box("red",Vector3(8,1.1,18),Vector3(0.85,0.15,3.5),Vector3(-0.5,0,0))
	b.primitive("sphere","playgreen",Vector3(8,2.4,19.3),Vector3(1.6,1.4,1.6))

func dormitory_nine() -> void:
	b.begin("DormitoryNine","莊敬九舍",Vector3(-199,0,-57),PI)
	b.landmark("莊敬九舍",Vector3.ZERO,Vector2(23,19),Vector3(0,0,15))
	mass("pink",Vector3(0,13.5,0),Vector3(23,27,19))
	secondary_windows(23,19,8)
	b.box("stone",Vector3(0,27.05,0),Vector3(23.5,0.35,19.5))
	for row in range(8):
		var y := 2.0+row*3.1
		b.box("stone",Vector3(0,y-1.45,9.7),Vector3(23,0.19,0.20))
		for col in range(7):
			var x := -9.0+col*3.0
			b.window_front(x,y,9.57,1.8,1.45)
			if row>0:
				ac(Vector3(x+0.55,y-1.05,9.98))
		for side in [-1.0,1.0]:
			for col in range(5):
				b.box("frame",Vector3(side*11.58,y,-7+col*3.2),Vector3(0.14,1.65,1.8))
				b.box("glass",Vector3(side*11.68,y,-7+col*3.2),Vector3(0.035,1.5,1.6))
	# Tall stone portal framing the recessed front doors in 096.
	for x in [-3.4,3.4]:
		mass("stone",Vector3(x,3.2,10.6),Vector3(0.65,6.4,2.4))
	b.box("stone",Vector3(0,6.35,10.6),Vector3(7.6,0.55,2.4))
	b.box("dark",Vector3(0,2.0,9.73),Vector3(5.8,3.4,0.1))
	b.window_front(0,2.0,9.85,4.6,2.4)
	steps(Vector3(0,0,14),8,0.13,6)
	b.sign_text("莊 敬 九 舍",Vector3(0,3.6,11.85),0.014,Color("51473e"))

func jing_tang() -> void:
	b.begin("JingTang","井塘樓・教育學院",Vector3(-193,0,-112))
	b.landmark("井塘樓",Vector3(0,0,-0.5),Vector2(36,15),Vector3(0,0,15))
	b.landmark("教育學院",Vector3(0,0,-0.5),Vector2(36,15),Vector3(0,0,15),true)
	# 098/101: true curved front, tall white ribs and a weather-darkened roof edge.
	for col in range(15):
		var x := -16.8+col*2.4
		var curve := 4.4*pow(x/16.8,2)
		var yaw := -atan(8.8*x/(16.8*16.8))
		b.part_transform = Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,curve+1.7))
		var bay_width := 2.44/cos(yaw)
		mass("tile",Vector3(0,7.1,-4.5),Vector3(bay_width,14.2,9))
		b.box("roof",Vector3(0,14.3,-4.2),Vector3(bay_width+0.12,0.45,10.2))
		b.box("trim",Vector3(-bay_width/2+0.1,7.1,0.28),Vector3(0.2,14.1,0.55))
		b.beam("trim",Vector3(-bay_width/2+0.1,12.9,0.3),Vector3(-bay_width/2+0.1,14,1.1),0.2)
		for row in range(4):
			b.window_front(0,2.0+row*3.35,0.15,1.58,1.85)
		b.box("green",Vector3(0,0.35,1.1),Vector3(bay_width-0.15,0.6,0.6))
	b.part_transform = Transform3D.IDENTITY
	for x in [-18.5,18.5]:
		mass("tile",Vector3(x,7.2,2.1),Vector3(2.6,14.4,12))
		b.box("roof",Vector3(x,14.4,2.1),Vector3(3.1,0.38,13))
	b.box("dark",Vector3(0,1.8,2.0),Vector3(4.9,3.0,0.12))
	b.window_front(0,1.8,2.08,3.8,2.6)
	steps(Vector3(0,0,8),9,0.14,6)
	b.box("stone",Vector3(0,3.7,3.8),Vector3(9,0.35,4.5))
	for x in [-3.5,3.5]:
		mass("trim",Vector3(x,1.8,5.5),Vector3(0.28,3.6,0.28))
	b.sign_text("教 育 學 院",Vector3(0,4.35,5.0),0.016,Color("b69859"))
	b.sign_text("井塘樓  JING TANG",Vector3(0,3.52,6.07),0.007,Color("59594e"))
	b.box("paving",Vector3(0,0.03,12),Vector3(44,0.06,12))
	for x in [-20,-14,14,20]:
		b.box("white",Vector3(x,0.08,12),Vector3(0.08,0.02,5.0))
	for x in [-17,17]:
		parked_car(Vector3(x,0,12),0)

func tree(at: Vector3, scale: float = 1.0, seed_value: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	b.primitive("cylinder","bark",at+Vector3(0,2.6*scale,0),Vector3(0.48,5.2,0.48)*scale)
	b.solid(at+Vector3(0,2*scale,0),Vector3(0.55,4,0.55)*scale)
	for branch in range(5):
		var angle := branch*TAU/5+0.3
		var end := at+Vector3(cos(angle)*2.3,5.4,sin(angle)*2.3)*scale
		b.beam("bark",at+Vector3(0,2.9,0)*scale,end,0.17*scale)
	for i in range(400):
		var angle := rng.randf_range(0,TAU)
		var radius := sqrt(rng.randf())*4.2*scale
		var p := at+Vector3(cos(angle)*radius,(5.5+sqrt(maxf(0,1-pow(radius/(4.3*scale),2)))*1.8+rng.randf_range(-0.6,0.6))*scale,sin(angle)*radius)
		var width := rng.randf_range(0.6,1.1)*scale
		b.primitive("quad",["leaf","leaflight","leafdark"][i%3],p,Vector3(width,width*1.3,1),Vector3(rng.randf_range(-1,1),rng.randf_range(0,TAU),rng.randf_range(-0.9,0.9)))

func parked_car(at: Vector3, yaw: float) -> void:
	# Unbranded parked vehicles establish pedestrian scale without shipping more GLBs.
	b.box("carblue",at+Vector3(0,0.65,0),Vector3(1.8,0.62,4.3),Vector3(0,yaw,0))
	b.box("glass",at+Vector3(0,1.16,0.15),Vector3(1.62,0.55,2.2),Vector3(0,yaw,0))
	b.box("carblue",at+Vector3(0,1.47,0.2),Vector3(1.63,0.1,1.85),Vector3(0,yaw,0))
	for x in [-0.88,0.88]:
		for z in [-1.25,1.3]:
			var p := Basis(Vector3.UP,yaw)*Vector3(x,0.43,z)
			b.primitive("cylinder","rubber",at+p,Vector3(0.6,0.2,0.6),Vector3(0,yaw,PI/2))
	b.solid(at+Vector3(0,0.8,0),Vector3(1.9,1.6,4.4),Vector3(0,yaw,0))

func path_segment(a: Vector3, z: Vector3, width: float, material: String = "road", y: float = 0.075) -> void:
	var delta := z-a
	var angle := atan2(delta.x,delta.z)
	b.box(material,(a+z)/2+Vector3.UP*y,Vector3(width,0.035,delta.length()+0.05),Vector3(0,angle,0))

func landscape() -> void:
	b.begin("LawEducationWalk","法學院－教育學院步行街區",Vector3.ZERO)
	# Replaces the old empty-lot patches and connects every photographed facade.
	b.box("lawn",Vector3(-163,0.012,-69),Vector3(178,0.022,94))
	b.box("lawn",Vector3(-180,0.012,-121),Vector3(84,0.022,10))
	b.box("lawn",Vector3(-123,0.012,-126),Vector3(78,0.022,20))
	# Four-way law intersection and eastward dormitory lane, all in the same frame.
	path_segment(Vector3(-77,0,-57),Vector3(-232,0,-57),8)
	path_segment(Vector3(-79,0,-25),Vector3(-79,0,-133),7)
	path_segment(Vector3(-144,0,-57),Vector3(-144,0,-98),6)
	path_segment(Vector3(-144,0,-98),Vector3(-228,0,-87),6)
	path_segment(Vector3(-228,0,-57),Vector3(-228,0,-119),6)
	path_segment(Vector3(-144,0,-98),Vector3(-110,0,-99),4,"brick",0.10)
	path_segment(Vector3(-110,0,-99),Vector3(-132,0,-103),4,"brick",0.10)
	path_segment(Vector3(-132,0,-103),Vector3(-132,0,-106),5,"brick",0.10)
	path_segment(Vector3(-191,0,-88),Vector3(-193,0,-97),6,"paving",0.10)
	path_segment(Vector3(-214,0,-91),Vector3(-238,0,-91),5,"brick",0.10)
	for z in [-51.7,-62.3]:
		path_segment(Vector3(-79,0,z),Vector3(-226,0,z),2.2,"paving",0.1)
		path_segment(Vector3(-79,0,z+0.9),Vector3(-226,0,z+0.9),0.15,"stone",0.12)
	for x in range(-221,-78,8):
		b.box("white",Vector3(x,0.1,-57),Vector3(3,0.025,0.09))
	for x in [-143,-85]:
		for i in range(8):
			b.box("white",Vector3(x,0.12,-60.7+i*1.04),Vector3(3.2,0.022,0.55))
	# Drains, utility covers and red no-parking curb along the photographed lane.
	for x in range(-220,-79,14):
		b.box("dark",Vector3(x,0.13,-61.4),Vector3(0.8,0.03,0.42))
		for slit in range(5):
			b.box("metal",Vector3(x-0.3+slit*0.15,0.15,-61.4),Vector3(0.035,0.02,0.4))
		b.box("red",Vector3(x+3,0.15,-61.7),Vector3(4.8,0.12,0.15))
	# 094: Li Yuan lawn kept open, with a standing stone and scattered shade trees.
	b.landmark("李園",Vector3(-169,0,-83),Vector2(28,28),Vector3(-148,0,-89),true)
	b.landmark("鳳凰林",Vector3(-99,0,-103),Vector2(14,10),Vector3(-98,0,-101),true)
	for entry in [[-156,-73,1.05],[-171,-70,1.1],[-180,-85,0.9],[-154,-90,0.8],[-216,-78,1.05],[-217,-103,1.0],[-96,-99,0.8],[-87,-112,0.9],[-150,-117,0.75],[-83,-41,0.8],[-146,-46,0.75],[-221,-35,0.9]]:
		tree(Vector3(entry[0],0,entry[1]),entry[2],int(-entry[0]*13-entry[1]))
	for x in [-95,-108,-122,-153,-178,-212]:
		tree(Vector3(x,0,-63.7),0.72,int(-x))
	mass("stone",Vector3(-173,1.0,-85),Vector3(1.5,2.0,0.65))
	b.sign_text("李 園",Vector3(-173,1.2,-84.65),0.012,Color("746246"))
	mass("stone",Vector3(-100,0.7,-104),Vector3(1.5,1.4,0.6))
	b.sign_text("鳳凰林",Vector3(-100,0.8,-103.68),0.009,Color("b69b66"))
	# Small red-roofed pavilion, benches and hedges visible beside the pool.
	for x in [-151,-147]:
		for z in [-126,-122]:
			mass("red",Vector3(x,1.45,z),Vector3(0.22,2.9,0.22))
	b.box("roof",Vector3(-149,3.05,-124),Vector3(5.5,0.22,5.5))
	for at in [Vector3(-157,0,-93),Vector3(-182,0,-76),Vector3(-98,0,-100),Vector3(-149,0,-123)]:
		for z in [-0.22,0,0.22]:
			b.box("fins",at+Vector3(0,0.53,z),Vector3(2.5,0.09,0.17))
		for x in [-0.95,0.95]:
			b.box("frame",at+Vector3(x,0.25,0),Vector3(0.09,0.5,0.5))
		b.solid(at+Vector3(0,0.35,0),Vector3(2.5,0.7,0.6))
	for x in [-102,-129,-166,-203,-225]:
		b.primitive("cylinder","frame",Vector3(x,2.7,-50.6),Vector3(0.12,5.4,0.12))
		b.box("frame",Vector3(x+0.45,5.3,-50.6),Vector3(1.0,0.12,0.12))
		b.box("cream",Vector3(x+0.8,5.24,-50.6),Vector3(0.75,0.12,0.36))
	for x in [-103,-116,-126]:
		parked_car(Vector3(x,0,-62.8),PI/2)
	# Route sign at the intersection makes the new district discoverable in play.
	mass("frame",Vector3(-82.2,1.6,-64),Vector3(0.10,3.2,0.10))
	b.box("green",Vector3(-82.2,2.9,-64),Vector3(3.8,1.15,0.12))
	b.sign_text("法學院 · 游泳館\n教育學院／井塘樓 ←",Vector3(-82.2,2.9,-63.92),0.009)
