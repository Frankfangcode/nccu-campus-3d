extends RefCounted
## 依實景照片重建兩棟地標。座標已確認；公尺尺寸仍待實測校正。
var b: Node3D

func law(builder: Node3D) -> void:
	b = builder
	b.begin("LawCollege","法學院",Vector3(-110,0,-78),PI)
	# 實景為長條板樓，端面不做左右鏡像。維持既定中心與出入口。
	b.box("paving",Vector3(0,0.04,3),Vector3(58,0.08,30))
	b.box("wall",Vector3(0,16.0,-1),Vector3(54,23,17))
	b.box("dark",Vector3(0,2.2,-2),Vector3(54,4.4,15))
	b.solid(Vector3(0,13.8,-1),Vector3(54,27.6,17))
	b.box("trim",Vector3(0,27.8,-1),Vector3(56.4,0.65,19.2))
	for x in [-19,16]:
		b.box("wall",Vector3(x,29.0,-3.5),Vector3(7,1.8,6))
	# 底層退縮門廊，二、三樓是一整條玻璃帷幕，不是重複住宅窗。
	for x in [-24,-18,-12,-6,6,12,18,24]:
		b.box("wall",Vector3(x,2.2,8.2),Vector3(0.65,4.4,2.4))
		b.solid(Vector3(x,2.2,8.2),Vector3(0.65,4.4,2.4))
	b.box("dark",Vector3(0,2.0,7.55),Vector3(15,3.5,0.1))
	for x in [-4.5,-1.5,1.5,4.5]:
		b.window_front(x,2.1,7.7,2.5,3.2)
	b.box("glass",Vector3(0,7.8,7.64),Vector3(49.5,5.5,0.08))
	for i in range(40):
		b.box("frame",Vector3(-24.5+i*1.26,7.8,7.77),Vector3(0.09,5.6,0.16))
	for y in [5.05,6.9,8.75,10.55]:
		b.box("frame",Vector3(0,y,7.78),Vector3(50,0.11,0.16))
	for y in [4.7,10.95]:
		b.box("trim",Vector3(0,y,8.05),Vector3(54.8,0.75,1.1))
	b.box("trim",Vector3(26,7.75,8.1),Vector3(1.5,6.9,1.2))
	# 五層灰色窗間牆；暖色直立格柵與白色細橫帶。
	for row in range(5):
		var y := 13.0+row*3.2
		for col in range(21):
			var x := -25.0+col*2.5
			b.window_front(x,y,7.64,1.45,1.75)
			b.box("fins",Vector3(x-1.04,y,8.02),Vector3(0.20,3.15,0.88))
		b.box("trim",Vector3(0,y-1.36,7.92),Vector3(54,0.12,0.8))
	# 照片中的不對稱密格柵：只占左段的中低層。
	for i in range(27):
		b.box("fins",Vector3(-25.2+i*0.49,14.4,8.65),Vector3(0.14,6.3,0.65))
	# 高層水平玻璃帶，跨越直格柵，為實景的重要識別特徵。
	b.box("glass",Vector3(12.5,22.6,8.55),Vector3(25,1.4,0.1))
	for i in range(24):
		b.box("frame",Vector3(0.15+i*1.07,22.6,8.64),Vector3(0.065,1.45,0.1))
	for y in [21.8,23.4]:
		b.box("trim",Vector3(12.5,y,8.65),Vector3(25.2,0.17,0.45))
	# 西端單一白色大框與兩個木色凸陽台；另一端保留簡單側窗。
	for z in [-7.6,0.4]:
		b.box("trim",Vector3(-27.4,15,z),Vector3(0.65,21,0.72))
	for y in [4.5,25.5]:
		b.box("trim",Vector3(-27.4,y,-3.6),Vector3(0.65,0.65,8.7))
	b.box("glass",Vector3(-27.15,14.8,-3.6),Vector3(0.1,19.5,6.8))
	for y in [6,9,12,15,18,21,24]:
		b.box("frame",Vector3(-27.3,y,-3.6),Vector3(0.12,0.13,6.8))
	for y in [11.1,18.0]:
		b.box("fins",Vector3(-28.0,y,-3.6),Vector3(1.1,1.65,6.6))
		for z in range(-6,0):
			b.box("wall",Vector3(-28.58,y,z),Vector3(0.02,1.6,0.035))
	b.sign_text("College of\nLAW",Vector3(-27.8,26.3,-3.6),0.025,Color.WHITE,-PI/2)
	for side in [-1,1]:
		for row in range(7):
			for z in [2.0,4.3,6.3]:
				b.box("glass",Vector3(side*27.09,3.3+row*3.25,z),Vector3(0.09,1.8,0.75))
	# 實拍背面沿用相同樓高，但不複製前側的白框及陽台。
	for row in range(8):
		for col in range(21):
			var x := -25.0+col*2.5
			b.box("glass",Vector3(x,2.5+row*3.15,-9.57),Vector3(1.55,1.75,0.08))
			b.box("fins",Vector3(x+1,2.5+row*3.15,-9.8),Vector3(0.16,3.1,0.55))
	b.sign_text("College of Law",Vector3(0,4.55,8.68),0.016)
	b.box("stone",Vector3(10,1.05,14.4),Vector3(7,2.1,0.65))
	b.solid(Vector3(10,1.05,14.4),Vector3(7,2.1,0.65))
	b.sign_text("法 學 院",Vector3(10,1.25,14.76),0.022,Color("685843"))
	for i in range(4):
		b.box("stone",Vector3(0,0.08*(i+1),11.5-i*0.4),Vector3(11,0.16*(i+1),0.42))
	b.landmark("法學院",Vector3(0,0,-1),Vector2(54,17),Vector3(0,0,21))

func pool(builder: Node3D, route: RefCounted) -> void:
	b = builder
	var glazing := StandardMaterial3D.new()
	glazing.albedo_color = Color(0.36,0.51,0.57,0.32)
	glazing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glazing.roughness = 0.16
	glazing.cull_mode = BaseMaterial3D.CULL_DISABLED
	b.materials["poolglass"] = glazing
	b.begin("SwimmingPool","游泳館",Vector3(-123,0,-120))
	b.landmark("游泳館",Vector3.ZERO,Vector2(38,20),Vector3(-9,0,15))
	b.box("brick",Vector3(0,0.035,4),Vector3(47,0.07,32))
	# 分開重建低入口棟及後方挑高泳池館；照片 071、080 可見兩個不同量體。
	for spec in [[Vector3(0,0.6,0),Vector3(38,1.2,20),"stone"],[Vector3(0,3.2,7),Vector3(38,4.0,6),"pink"],[Vector3(0,6.65,7),Vector3(38,2.9,6),"tile"]]:
		b.box(spec[2],spec[0],spec[1])
		b.solid(spec[0],spec[1])
	# 後方主館保持內部挑空，兩端整面玻璃可看見泳道與屋架。
	b.box("tile",Vector3(0,2,-9.8),Vector3(38,4,0.4))
	b.solid(Vector3(0,5,-9.8),Vector3(38,10,0.4))
	b.box("roof",Vector3(0,10.5,-3),Vector3(39.2,0.3,15.2),Vector3(0.10,0,0))
	b.box("roof",Vector3(0,9.15,4.15),Vector3(38.7,2.0,0.18))
	for x in range(-19,20):
		b.box("metal",Vector3(x,9.2,4.26),Vector3(0.05,2.05,0.06))
	for x in range(-19,20):
		b.box("metal",Vector3(x,10.7,-3),Vector3(0.045,0.08,15.2),Vector3(0.10,0,0))
	# 入口棟的低平屋簷、雙層通風帶與大窗。
	for y in [5.1,7.85,8.45]:
		b.box("roof",Vector3(0,y,9.95),Vector3(39.2,0.24,0.9))
	for x in range(-17,18,4):
		b.window_front(x,6.55,10.04,2.7,1.7)
		b.box("tile",Vector3(x+1.6,6.55,10.13),Vector3(0.6,2.1,0.25))
		for y in [4.55,8.12]:
			b.box("dark",Vector3(x,y,10.06),Vector3(3.0,0.44,0.06))
			for slit in range(5):
				b.box("metal",Vector3(x,y-0.18+slit*0.085,10.12),Vector3(3.0,0.025,0.03))
	# 玻璃側立面：石基座、下層小窗、上層高窗、白色結構柱。
	for side in [-1,1]:
		b.solid(Vector3(side*19.1,5,-3),Vector3(0.3,10,14))
		for col in range(6):
			var z := -8.6+col*2.5
			b.box("poolglass",Vector3(side*19.1,2.7,z),Vector3(0.08,2.35,2.3))
			b.box("poolglass",Vector3(side*19.1,7.3,z),Vector3(0.08,4.45,2.3))
			b.box("trim",Vector3(side*19.22,5.25,z-1.2),Vector3(0.35,9.0,0.22))
			b.box("frame",Vector3(side*19.22,7.2,z),Vector3(0.15,0.075,2.45))
		for y in [1.4,4.15,4.8]:
			b.box("tile",Vector3(side*19.22,y,-3),Vector3(0.38,0.5,14))
	# 內部水面與泳道，透過兩側玻璃讀出泳池用途。
	b.box("blue",Vector3(0,1.24,-3),Vector3(33,0.035,10))
	for z in [-7,-5,-3,-1,1]:
		b.box("white",Vector3(0,1.27,z),Vector3(33,0.02,0.065))
	for x in range(-16,17,4):
		b.beam("cream",Vector3(x,8.8,3.6),Vector3(x,10.2,-9.6),0.16)
	# 入口照片 077：寬階梯、雙柱厚雨遮、旁側無障礙坡道。
	for x in [-11.5,-9,-6.5]:
		b.window_front(x,2.5,10.22,2.2,2.8)
	route.steps(Vector3(-9,0,14),11,0.14,7)
	b.box("pink",Vector3(-9,4.5,11.3),Vector3(13,0.75,3.4))
	for x in [-14.8,-3.2]:
		b.box("tile",Vector3(x,2.3,12.25),Vector3(0.5,4.6,0.55))
		b.solid(Vector3(x,2.3,12.25),Vector3(0.5,4.6,0.55))
	for x in [-15.7,-2.3]:
		route.rail(Vector3(x,0,14.5),Vector3(x,1.0,11.5))
	b.box("stone",Vector3(8,0.52,11.7),Vector3(14,0.2,1.8),Vector3(0,0,-0.065))
	b.solid(Vector3(8,0.52,11.7),Vector3(14,0.2,1.8),Vector3(0,0,-0.065),true)
	route.rail(Vector3(1,1,12.65),Vector3(15,0.1,12.65))
	for x in [0,5]:
		b.box("blue",Vector3(x,2.7,10.12),Vector3(4.3,2.7,0.08))
	# 轉角的直式名稱、橘色英文牌及設備箱。
	b.sign_text("游\n泳\n館",Vector3(17,3.7,10.2),0.013,Color("9cb9cd"))
	b.box("red",Vector3(16,2.5,10.15),Vector3(4.2,0.65,0.12))
	b.sign_text("Swimming Hall",Vector3(16,2.5,10.24),0.007,Color("d5e3e8"))
	b.box("stone",Vector3(18,1.75,10.45),Vector3(0.9,1.65,0.3))
	b.beam("metal",Vector3(18.7,0.3,10.5),Vector3(18.7,3.4,10.5),0.09)
