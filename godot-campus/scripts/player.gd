extends CharacterBody3D

const Actor = preload("res://scripts/actor.gd")
var visual: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var enabled := false
var yaw := 0.0
var pitch := -0.16
var touch_move := Vector2.ZERO
var touch_sprint := false
var touch_jump := false
var stamina := 100.0
var driving := false
var manual_look_until := 0
var rendered_camera_distance := 4.8

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	visual = Actor.new()
	add_child(visual)
	visual.setup()
	visual.rotation.y = PI
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.55
	arm = SpringArm3D.new()
	arm.spring_length = 4.8
	arm.margin = 0.2
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	var camera_clearance := SphereShape3D.new()
	camera_clearance.radius = 0.22
	arm.shape = camera_clearance
	pivot.add_child(arm)
	var camera_mount := Node3D.new()
	arm.add_child(camera_mount)
	camera = Camera3D.new()
	camera.fov = 64.0
	camera.near = 0.12
	camera.far = 950.0
	camera_mount.add_child(camera)
	camera.current = true

func _process(delta: float) -> void:
	# 接近牆壁立即避讓，離開遮擋後緩慢拉遠，避免轉頭時忽近忽遠。
	var available := arm.get_hit_length()
	rendered_camera_distance = minf(available,lerpf(rendered_camera_distance,available,1.0-exp(-7.0*delta)))
	camera.position.z = rendered_camera_distance-available

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -0.9, 0.35)
		manual_look_until = Time.get_ticks_msec()+1800
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(2.0, arm.spring_length - 0.4)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(8.0, arm.spring_length + 0.4)

func _physics_process(delta: float) -> void:
	var camera_weight := 1.0-exp(-20.0*delta)
	pivot.rotation.x = lerp_angle(pivot.rotation.x,pitch,camera_weight)
	pivot.rotation.y = lerp_angle(pivot.rotation.y,yaw,camera_weight)
	if driving:
		visual.visible = false
		return
	visual.visible = true
	var input := Input.get_vector("left", "right", "forward", "back") + touch_move if enabled else Vector2.ZERO
	input = input.limit_length()
	var direction := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
	var sprint := enabled and (Input.is_action_pressed("sprint") or touch_sprint) and stamina > 1 and input.length() > 0.1
	var speed := 6.4 if sprint else 3.1
	stamina = clampf(stamina + (-17.0 if sprint else 12.0) * delta, 0, 100)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 18)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 18)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	elif enabled and (Input.is_action_just_pressed("jump") or touch_jump):
		velocity.y = 6.5
	touch_jump = false
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta * 12)
	visual.animate(Vector2(velocity.x, velocity.z).length())
	camera.fov = lerpf(camera.fov, 70.0 if sprint else 64.0, delta * 3)
	if position.y < -12:
		position = Vector3(-2, 2, 21)
		velocity = Vector3.ZERO
