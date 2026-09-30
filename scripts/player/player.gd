extends CharacterBody3D
## First-person player controller (M1a) + stealth hooks (M2a).
## WASD movement relative to camera yaw, mouse look, crouch, lean, zoom, interact.
## M2a: is_aiming_at_feet (camera-center raycast to the "feet" group), is_hidden
## (set by HidingSpot), movement noise via NoiseSystem, photo-capture noise.

const WALK_SPEED := 4.0
const SPRINT_SPEED := 6.5
const CROUCH_WALK_SPEED := 2.0
const GRAVITY := -20.0

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2
const STAND_CAMERA_Y := 1.6
const CROUCH_CAMERA_Y := 1.0
const HIDDEN_CAMERA_DIP := 0.3

const LEAN_AMOUNT := 0.4
const LEAN_FORWARD := 0.1
const LEAN_ROLL_DEG := 5.0

const NORMAL_FOV := 70.0
const ZOOM_FOV := 10.0

const INTERACT_RANGE := 3.0
const AIM_RANGE := 60.0

const NOISE_INTERVAL := 0.4
const CROUCH_NOISE_RADIUS := 1.5
const WALK_NOISE_RADIUS := 4.0
const SPRINT_NOISE_RADIUS := 11.0
const PHOTO_NOISE_RADIUS := 8.0
const PHOTO_NOISE_LOUDNESS := 4.0

const SMOOTHING := 10.0

@onready var camera: Camera3D = $Camera
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Exposed state (read by UI / stealth systems).
var is_crouching := false
var is_sprinting := false
var is_moving := false
var is_zoomed := false
var is_hidden := false  # set by HidingSpot; breaks NPC line of sight
var is_aiming_at_feet := false  # camera-center ray hits the "feet" group
var current_speed := 0.0

var _yaw := 0.0
var _pitch := 0.0
var _crouch_factor := 0.0  # 0.0 standing .. 1.0 crouched
var _lean := 0.0           # -1.0 .. 1.0 smoothed lean target
var _noise_timer := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")


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
	elif event.is_action_pressed("capture"):
		_capture()


func _physics_process(delta: float) -> void:
	# --- State ---
	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	is_zoomed = Input.is_action_pressed("zoom")
	is_aiming_at_feet = _raycast_feet()

	# --- Crouch: lerp capsule height + camera height ---
	var target_crouch := 1.0 if is_crouching else 0.0
	_crouch_factor = lerpf(_crouch_factor, target_crouch, SMOOTHING * delta)
	var height := lerpf(STAND_HEIGHT, CROUCH_HEIGHT, _crouch_factor)
	var cam_y := lerpf(STAND_CAMERA_Y, CROUCH_CAMERA_Y, _crouch_factor)
	if is_hidden:
		cam_y -= HIDDEN_CAMERA_DIP  # camera dips slightly while hidden
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

	# --- Movement noise (silent while hidden) ---
	_emit_movement_noise(delta)


## Camera-center raycast to the "feet" group (M2a). True when the player is
## aiming at an NPC's feet — the creepy behavior that raises NPC creep.
func _raycast_feet() -> bool:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * AIM_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	# Skip the player's own body and all NPC bodies so the ray can reach the
	# feet trigger colliders (an NPC capsule would otherwise occlude the feet).
	var exclude: Array[RID] = [get_rid()]
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is PhysicsBody3D:
			exclude.append(npc.get_rid())
	query.exclude = exclude
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false
	var node := result.collider as Node
	while node != null:
		if node.is_in_group("feet"):
			return true
		node = node.get_parent()
	return false


## Periodic movement noise: crouch ~1.5, walk ~4, sprint ~11 radius, every
## ~0.4s while moving. Silent while hidden or standing still.
func _emit_movement_noise(delta: float) -> void:
	if is_hidden or not is_moving:
		_noise_timer = 0.0
		return
	_noise_timer -= delta
	if _noise_timer > 0.0:
		return
	_noise_timer = NOISE_INTERVAL
	var radius := CROUCH_NOISE_RADIUS if is_crouching else (SPRINT_NOISE_RADIUS if is_sprinting else WALK_NOISE_RADIUS)
	NoiseSystem.emit_noise(global_position, radius, radius * 0.5)


## Photo capture (M2a hook): emits a small noise (~8 radius) so nearby NPCs
## notice the shutter. Full capture scoring comes in a later milestone.
func _capture() -> void:
	NoiseSystem.emit_noise(global_position, PHOTO_NOISE_RADIUS, PHOTO_NOISE_LOUDNESS)


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
