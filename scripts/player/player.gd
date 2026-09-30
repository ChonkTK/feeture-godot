extends CharacterBody3D
## First-person player controller (M1a).
## WASD movement relative to camera yaw, mouse look, crouch, lean, zoom, interact.

const WALK_SPEED := 4.0
const SPRINT_SPEED := 6.5
const CROUCH_WALK_SPEED := 2.0
const GRAVITY := -20.0

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const STAND_CAMERA_Y := 1.6
const CROUCH_CAMERA_Y := 1.0

const LEAN_AMOUNT := 0.4
const LEAN_FORWARD := 0.1
const LEAN_ROLL_DEG := 5.0

const NORMAL_FOV := 70.0
const ZOOM_FOV := 10.0

const INTERACT_RANGE := 3.0

const SMOOTHING := 10.0

@onready var camera: Camera3D = $Camera
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Exposed state (read by UI / stealth systems).
var is_crouching := false
var is_sprinting := false
var is_moving := false
var is_zoomed := false
var is_hidden := false  # placeholder; M2 hiding uses this
var current_speed := 0.0

var _yaw := 0.0
var _pitch := 0.0
var _crouch_factor := 0.0  # 0.0 standing .. 1.0 crouched
var _lean := 0.0           # -1.0 .. 1.0 smoothed lean target


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		var sens := Settings.mouse_sensitivity
		var dy := mm.relative.y
		if Settings.invert_y:
			dy = -dy
		_yaw -= mm.relative.x * sens
		_pitch -= dy * sens
		_pitch = clampf(_pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		rotation.y = _yaw
		camera.rotation.x = _pitch
	elif event.is_action_pressed("interact"):
		_interact()


func _physics_process(delta: float) -> void:
	# --- State ---
	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	is_zoomed = Input.is_action_pressed("zoom")

	# --- Crouch: lerp capsule height + camera height ---
	var target_crouch := 1.0 if is_crouching else 0.0
	_crouch_factor = lerpf(_crouch_factor, target_crouch, SMOOTHING * delta)
	var height := lerpf(STAND_HEIGHT, CROUCH_HEIGHT, _crouch_factor)
	var cam_y := lerpf(STAND_CAMERA_Y, CROUCH_CAMERA_Y, _crouch_factor)
	var shape := collision_shape.shape as CapsuleShape3D
	shape.height = height
	collision_shape.position.y = height * 0.5  # keep feet planted at y=0

	# --- Lean: camera local x / z / roll; body stays put ---
	var lean_input := 0.0
	if Input.is_action_pressed("lean_left"):
		lean_input -= 1.0
	if Input.is_action_pressed("lean_right"):
		lean_input += 1.0
	_lean = lerpf(_lean, lean_input, SMOOTHING * delta)
	camera.position = Vector3(_lean * LEAN_AMOUNT, cam_y, LEAN_FORWARD)
	camera.rotation.z = _lean * deg_to_rad(LEAN_ROLL_DEG)

	# --- Zoom: FOV lerp ---
	var target_fov := ZOOM_FOV if is_zoomed else NORMAL_FOV
	camera.fov = lerpf(camera.fov, target_fov, SMOOTHING * delta)

	# --- Movement: WASD relative to camera yaw ---
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	is_moving = direction.length() > 0.01
	var speed := CROUCH_WALK_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y += GRAVITY * delta
	move_and_slide()
	current_speed = Vector2(velocity.x, velocity.z).length()


func _interact() -> void:
	print("Interact pressed")
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * INTERACT_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space.intersect_ray(query)
	if result.is_empty():
		print("Interact hit: nothing")
	else:
		print("Interact hit: ", result.collider, " at ", result.position)
