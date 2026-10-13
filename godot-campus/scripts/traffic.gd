extends Node3D
## One M.A.V.S traffic car looping along Zhinan Road; it knocks the player aside on impact.
const CAR := "res://addons/M.A.V.S/Vehicle/AI_Vehicles/AI_Muscle_Car.tscn"
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
var car: VehicleBody3D
var target: PathFollow3D
var lane: Path3D
var hit_cooldown := 0.0
var stuck_time := 0.0

func _ready() -> void:
	# Run after the M.A.V.S car script so the U-turn braking below is not overwritten.
	process_physics_priority = 10
	lane = Path3D.new()
	lane.set_script(load("res://addons/M.A.V.S/Scripts/MPathManager.gd"))
	lane.curve = loop_curve()
	add_child(lane)
	# The lane leads back into itself, so the car keeps circling.
	var next: Array[MPathManager] = [lane]
	lane.roads = next
	target = load(TARGET).instantiate()
	target.speed = DRIVE_FORCE
	lane.add_child(target)
	target.get_node("MeshInstance3D").hide()
	car = load(CAR).instantiate()
	car.target_ray = target
	car.take_speed_from_target = true
	car.boost_speed = true
	add_child(car)
	target.target_veh = car
	if car.veh_indicator:
		car.veh_indicator.hide()
	place_at_start()

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

func place_at_start() -> void:
	target.progress = 6.0
	target.active = true
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
	# M.A.V.S cars drive along their local +Z axis.
	car.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(X_MIN, 0.6, LANE_OUT))
	stuck_time = 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(car):
		return
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	var speed := car.linear_velocity.length()
	# Recover a car that flipped, fell or wedged itself somewhere.
	stuck_time = stuck_time + delta if speed < 0.5 else 0.0
	if car.global_position.y < -3.0 or car.global_basis.y.y < 0.3 or stuck_time > 12.0:
		place_at_start()
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
