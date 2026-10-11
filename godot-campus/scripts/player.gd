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
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 64.0
	camera.near = 0.12
	camera.far = 950.0
	arm.add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -0.9, 0.35)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(2.0, arm.spring_length - 0.4)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(8.0, arm.spring_length + 0.4)

func _physics_process(delta: float) -> void:
	pivot.rotation = Vector3(pitch, yaw, 0)
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
