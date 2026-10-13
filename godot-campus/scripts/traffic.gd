extends Node3D
## M.A.V.S traffic cars looping along Zhinan Road; they knock the player aside on impact.
# One entry per moving car; they start evenly spaced around the loop.
const CARS := [
	"res://addons/M.A.V.S/Vehicle/AI_Vehicles/AI_Muscle_Car.tscn",
	"res://addons/M.A.V.S/Vehicle/AI_Vehicles/AI_TRG.tscn",
]
const TARGET := "res://addons/M.A.V.S/Scenes/Traffic_Target.tscn"
const LANE_OUT := 48.0   # +x direction, right-hand traffic
const LANE_BACK := 39.6  # -x direction; tree trunks stand along z = 37
const X_MIN := -110.0
const X_MAX := 60.0     # solid blocks stand on the outbound lane from x = 78
const DRIVE_FORCE := 40.0  # M.A.V.S engine force; also how fast the guide point runs ahead
const CRUISE_SPEED := 10.0 # m/s on the straights (36 km/h)
const TURN_SPEED := 3.2    # m/s through the U-turns
const TURN_ZONE := 22.0

var player: CharacterBody3D
var cars: Array[VehicleBody3D] = []
var targets: Array[PathFollow3D] = []
var stuck_times: Array[float] = []
var lane: Path3D
var hit_cooldown := 0.0

func _ready() -> void:
	# Run after the M.A.V.S car script so the U-turn braking below is not overwritten.
	process_physics_priority = 10
	lane = Path3D.new()
	lane.set_script(load("res://addons/M.A.V.S/Scripts/MPathManager.gd"))
	lane.curve = loop_curve()
	add_child(lane)
	# The lane leads back into itself, so the cars keep circling.
	var next: Array[MPathManager] = [lane]
	lane.roads = next
	for path in CARS:
		var target: PathFollow3D = load(TARGET).instantiate()
		target.speed = DRIVE_FORCE
		lane.add_child(target)
		target.get_node("MeshInstance3D").hide()
		var car: VehicleBody3D = load(path).instantiate()
		car.collision_layer = 3
		car.collision_mask = 3
		car.target_ray = target
		car.take_speed_from_target = true
		car.boost_speed = true
		add_child(car)
		target.target_veh = car
		if car.veh_indicator:
			car.veh_indicator.hide()
		cars.append(car)
		targets.append(target)
		stuck_times.append(0.0)
		place_at_start(cars.size() - 1)

func loop_curve() -> Curve3D:
	var curve := Curve3D.new()
	var mid := (LANE_OUT + LANE_BACK) / 2.0
	var radius := (LANE_OUT - LANE_BACK) / 2.0
	var y := 0.6
	curve.add_point(Vector3(X_MIN, y, LANE_OUT))
	curve.add_point(Vector3(X_MAX, y, LANE_OUT))
	for step in range(1, 12):
		var a := PI * step / 12.0
		curve.add_point(Vector3(X_MAX + sin(a) * radius, y, mid + cos(a) * radius))
	curve.add_point(Vector3(X_MAX, y, LANE_BACK))
	curve.add_point(Vector3(X_MIN, y, LANE_BACK))
	for step in range(1, 12):
		var a := PI * step / 12.0
		curve.add_point(Vector3(X_MIN - sin(a) * radius, y, mid - cos(a) * radius))
	curve.add_point(Vector3(X_MIN, y, LANE_OUT))
	return curve

func place_at_start(index: int) -> void:
	var curve := lane.curve
	var length := curve.get_baked_length()
	var behind := length * index / CARS.size()
	var target := targets[index]
	var car := cars[index]
	target.progress = behind + 6.0
	target.active = true
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
	var from := curve.sample_baked(behind)
	var heading := (curve.sample_baked(behind + 2.0) - from).normalized()
	# M.A.V.S cars drive along their local +Z axis.
	car.global_transform = Transform3D(Basis.looking_at(-heading), from)
	stuck_times[index] = 0.0

func _physics_process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	for index in cars.size():
		drive(index, delta)

func drive(index: int, delta: float) -> void:
	var car := cars[index]
	if not is_instance_valid(car):
		return
	var speed := car.linear_velocity.length()
	# Recover a car that flipped, fell or wedged itself somewhere.
	stuck_times[index] = stuck_times[index] + delta if speed < 0.5 else 0.0
	if car.global_position.y < -3.0 or car.global_basis.y.y < 0.3 or stuck_times[index] > 12.0:
		place_at_start(index)
		return
	var turning := car.global_position.x > X_MAX - TURN_ZONE or car.global_position.x < X_MIN + TURN_ZONE
	var limit := TURN_SPEED if turning else CRUISE_SPEED
	if speed > limit:
		car.engine_force = 0.0
		car.brake = 4.0 if speed > limit + 1.5 else 0.0
	if not is_instance_valid(player) or player.driving or hit_cooldown > 0.0 or speed < 1.5:
		return
	var local := car.global_transform.affine_inverse() * player.global_position
	if absf(local.x) < 1.35 and absf(local.z) < 2.85 and local.y > -0.5 and local.y < 2.2:
		var forward := car.linear_velocity.normalized()
		var side := car.global_basis.x * (1.0 if local.x >= 0.0 else -1.0)
		var push := (forward * 0.55 + side * 0.85).normalized() * maxf(14.0, speed * 1.6)
		player.velocity = Vector3(push.x, 6.0, push.z)
		hit_cooldown = 1.0
