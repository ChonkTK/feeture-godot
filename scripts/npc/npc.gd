class_name NPC
extends CharacterBody3D
## Wander NPC (M1c) + stealth senses (M2a): per-NPC creep (0..100), state machine
## {IDLE, SUSPICIOUS, ALERTED, SEARCHING}, line-of-sight from the eyes, a
## translucent vision cone, noise hearing, alert call-outs and caught detection.
##
## Creep rule: creep rises ONLY when the NPC can see the player AND the player
## is zoomed in on feet (is_zoomed && is_aiming_at_feet), or when the player
## takes a photo (noise). Just being seen does NOT raise creep.

const WALK_SPEED := 1.5
const ALERT_SPEED := 2.4
const GRAVITY := -20.0
const ARRIVE_DIST := 0.35

# --- Senses (M2a) ---
const EYE_HEIGHT := 1.6
const SIGHT_RANGE := 14.0
const FOV_HALF_ANGLE_DEG := 70.0
const CREEP_GAIN_RATE := 13.0
const CREEP_ALERT_THRESHOLD := 50.0
const CREEP_CAUGHT_THRESHOLD := 100.0
const CLOSE_RANGE := 2.5
const CAUGHT_RANGE := 3.0
const LOST_SIGHT_TIME := 2.0
const SEARCH_TIME := 4.0
const DECAY_GRACE := 1.5
const CALM_THRESHOLD := 15.0
const ALERT_CALL_RADIUS := 12.0
const ALERT_CALL_BOOST := 15.0
const CONE_LENGTH := 14.0
const CONE_HALF_ANGLE_DEG := 35.0

const NAMES: Array[String] = [
	"Bubbles", "Sunny", "Mango", "Pepper", "Waffles", "Noodle", "Pickle",
	"Sprout", "Biscuit", "Taco", "Mochi", "Ziggy", "Fizz", "Gumbo", "Jelly",
	"Kiki", "Lola", "Momo", "Nimbus", "Ollie", "Pip", "Rusty", "Sable",
	"Tofu", "Wren", "Yuki", "Zazu",
]

const SKIN_TONES: Array[Color] = [
	Color(0.96, 0.8, 0.68), Color(0.9, 0.7, 0.55), Color(0.78, 0.57, 0.42),
	Color(0.62, 0.42, 0.3), Color(0.45, 0.3, 0.22), Color(0.3, 0.2, 0.15),
]
const SHIRT_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.3), Color(0.3, 0.6, 0.9), Color(0.2, 0.7, 0.4),
	Color(0.95, 0.8, 0.2), Color(0.6, 0.3, 0.8), Color(0.95, 0.5, 0.2),
	Color(0.2, 0.8, 0.8), Color(0.9, 0.4, 0.7),
]
const PANTS_COLORS: Array[Color] = [
	Color(0.2, 0.25, 0.35), Color(0.4, 0.35, 0.3), Color(0.25, 0.4, 0.3),
	Color(0.5, 0.5, 0.5), Color(0.3, 0.3, 0.45),
]
const HAIR_COLORS: Array[Color] = [
	Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.85, 0.7, 0.3),
	Color(0.55, 0.2, 0.15), Color(0.75, 0.75, 0.75), Color(0.2, 0.15, 0.1),
]
const SHOE_COLORS: Array[Color] = [
	Color(0.15, 0.15, 0.15), Color(0.95, 0.95, 0.95), Color(0.8, 0.2, 0.2),
	Color(0.2, 0.4, 0.8), Color(0.6, 0.4, 0.2),
]

enum State { IDLE, SUSPICIOUS, ALERTED, SEARCHING }
enum AiState { IDLE, WALKING }

# Exposed stealth state (M2a).
var state: State = State.IDLE
var creep := 0.0
var last_seen_pos := Vector3.ZERO

## Test/override hook: when set, this NPC watches this player instead of
## GameManager.player (used by headless tests).
var player_ref: Node3D = null

# Identity (exposed for M2 hiding / photo targets).
var npc_name: String = ""
var is_target: bool = false

# Wander bounds (level ground rect, world space).
var bounds: Rect2 = Rect2(-20.0, -20.0, 40.0, 40.0)

var _ai_state := AiState.IDLE
var _target := Vector3.ZERO
var _idle_time := 0.0
var _look_timer := 0.0
var _yaw := 0.0
var _visible := false
var _lost_sight_time := 0.0
var _search_time := 0.0
var _search_yaw := 0.0
var _called_out := false
var _cone: MeshInstance3D = null


func _ready() -> void:
	npc_name = NAMES[randi() % NAMES.size()]
	_build_visuals()
	_build_vision_cone()
	add_to_group("npcs")
	_pick_target()
	_ai_state = AiState.WALKING


## Called by GameManager before add_child: sets spawn point and wander bounds.
func setup(spawn: Vector3, level_bounds: Rect2) -> void:
	bounds = level_bounds
	position = spawn
	_pick_target()
	_ai_state = AiState.WALKING


func _physics_process(delta: float) -> void:
	var p := _current_player()
	_visible = _line_of_sight(p)
	_update_state(delta, p)
	_update_movement(delta)
	_update_vision_cone()
	velocity.y += GRAVITY * delta
	move_and_slide()


## M2a: adds creep (clamped 0..100). Called by NoiseSystem and alert call-outs.
func add_creep(amount: float) -> void:
	if amount <= 0.0:
		return
	creep = minf(creep + amount, CREEP_CAUGHT_THRESHOLD)


## M2a: noise/alert hook — adds creep and points the NPC at the source.
func hear_noise(pos: Vector3, amount: float) -> void:
	if amount <= 0.0:
		return
	add_creep(amount)
	last_seen_pos = pos
	if state == State.IDLE:
		state = State.SUSPICIOUS
	elif state == State.SEARCHING:
		last_seen_pos = pos


func _current_player() -> Node3D:
	if player_ref != null:
		return player_ref
	# Runtime lookup: autoload identifiers are not resolvable at compile time
	# when this script is loaded during autoload init or from a --script test.
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return null
	return gm.player


## M2a: distance + view angle + occlusion raycast from the eyes. A hidden
## player is never visible.
func _line_of_sight(p: Node3D) -> bool:
	if p == null or p.is_hidden:
		return false
	var eye := global_position + Vector3(0.0, EYE_HEIGHT, 0.0)
	var target := p.global_position + Vector3(0.0, 1.2, 0.0)
	var to_target := target - eye
	var dist := to_target.length()
	if dist > SIGHT_RANGE:
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.angle_to(to_target.normalized()) > deg_to_rad(FOV_HALF_ANGLE_DEG):
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(eye, target)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return true
	return result.collider == p


func _update_state(delta: float, p: Node3D) -> void:
	if _visible:
		last_seen_pos = p.global_position
		_lost_sight_time = 0.0
		# Creep rises ONLY while the player is zoomed in on feet.
		if p.is_zoomed and p.is_aiming_at_feet:
			creep = minf(creep + CREEP_GAIN_RATE * delta, CREEP_CAUGHT_THRESHOLD)
		if state == State.IDLE or state == State.SEARCHING:
			state = State.SUSPICIOUS
		# Caught: creep at 100 while visible.
		if creep >= CREEP_CAUGHT_THRESHOLD:
			_caught()
			return
	else:
		_lost_sight_time += delta

	var dist := INF
	if p != null:
		dist = global_position.distance_to(p.global_position)

	# Very close: alert immediately (from any non-alerted state).
	if state != State.ALERTED and dist < CLOSE_RANGE:
		_enter_alerted()
		return

	# Caught: ALERTED and within caught range.
	if state == State.ALERTED and dist < CAUGHT_RANGE:
		_caught()
		return

	# Suspicion-driven transitions.
	match state:
		State.SUSPICIOUS:
			if creep >= CREEP_ALERT_THRESHOLD:
				_enter_alerted()
			elif not _visible and _lost_sight_time > LOST_SIGHT_TIME:
				_enter_searching()
			elif not _visible and creep <= CALM_THRESHOLD:
				state = State.IDLE
				_pick_target()
				_ai_state = AiState.WALKING
		State.ALERTED:
			if not _visible and _lost_sight_time > LOST_SIGHT_TIME:
				_enter_searching()
		State.SEARCHING:
			_search_time -= delta
			if _search_time <= 0.0 or creep <= 0.0:
				state = State.IDLE
				_pick_target()
				_ai_state = AiState.WALKING

	# Decay while unseen (after a grace period; x2 faster while player hidden).
	if not _visible and _lost_sight_time > DECAY_GRACE and creep > 0.0:
		var rate := _decay_rate()
		if p != null and p.is_hidden:
			rate *= 2.0
		creep = maxf(0.0, creep - rate * delta)


func _decay_rate() -> float:
	match state:
		State.IDLE:
			return 6.0
		State.SUSPICIOUS:
			return 2.0
		State.SEARCHING:
			return 4.0
		State.ALERTED:
			return 0.5
	return 6.0


func _enter_alerted() -> void:
	if state == State.ALERTED:
		return
	state = State.ALERTED
	_called_out = false
	_lost_sight_time = 0.0
	_ai_state = AiState.WALKING
	_call_out()


## One-time call-out: nearby NPCs within 12m get +15 creep via hear_noise.
func _call_out() -> void:
	if _called_out:
		return
	_called_out = true
	for other in get_tree().get_nodes_in_group("npcs"):
		if other == null or other == self:
			continue
		if global_position.distance_to(other.global_position) <= ALERT_CALL_RADIUS:
			other.hear_noise(global_position, ALERT_CALL_BOOST)


func _enter_searching() -> void:
	state = State.SEARCHING
	_search_time = SEARCH_TIME
	_lost_sight_time = 0.0
	_called_out = false
	_ai_state = AiState.WALKING
	_search_yaw = _yaw


func _caught() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		gm.handle_caught()


# --- Per-state movement ------------------------------------------------------

func _update_movement(delta: float) -> void:
	match state:
		State.IDLE:
			_wander(delta)
		State.SUSPICIOUS:
			velocity.x = 0.0
			velocity.z = 0.0
			var p := _current_player()
			if p != null:
				_face_point(p.global_position, delta)
		State.ALERTED:
			var p := _current_player()
			if p != null and _visible:
				_face_point(p.global_position, delta)
				var to_p := p.global_position - global_position
				to_p.y = 0.0
				if to_p.length() > 1.2:
					var dir := to_p.normalized()
					velocity.x = dir.x * ALERT_SPEED
					velocity.z = dir.z * ALERT_SPEED
				else:
					velocity.x = 0.0
					velocity.z = 0.0
			else:
				_move_to_point(last_seen_pos, delta, WALK_SPEED)
		State.SEARCHING:
			if _search_time > SEARCH_TIME * 0.5:
				_move_to_point(last_seen_pos, delta, WALK_SPEED)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				_search_yaw += delta * 2.0
				rotation.y = _search_yaw


func _wander(delta: float) -> void:
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_idle_time -= delta
			_look_timer -= delta
			if _look_timer <= 0.0:
				_look_timer = randf_range(1.0, 3.0)
				_yaw += deg_to_rad(randf_range(-70.0, 70.0))
				rotation.y = _yaw
			if _idle_time <= 0.0:
				_pick_target()
				_ai_state = AiState.WALKING
		AiState.WALKING:
			_move_to_point(_target, delta, WALK_SPEED)
			if global_position.distance_to(_target) < ARRIVE_DIST:
				_idle_time = randf_range(1.0, 3.0)
				_ai_state = AiState.IDLE


func _face_point(point: Vector3, delta: float) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	var dir := to.normalized()
	_yaw = lerp_angle(_yaw, atan2(-dir.x, -dir.z), 8.0 * delta)
	rotation.y = _yaw


func _move_to_point(point: Vector3, delta: float, speed: float) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() < ARRIVE_DIST:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := to.normalized()
	_yaw = lerp_angle(_yaw, atan2(-dir.x, -dir.z), 5.0 * delta)
	rotation.y = _yaw
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed


func _pick_target() -> void:
	_target = Vector3(
		randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
		0.0,
		randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
	)


# --- Vision cone (M2a) ------------------------------------------------------

## Translucent cone from the eyes along the look direction (subtle).
func _build_vision_cone() -> void:
	var cone := MeshInstance3D.new()
	cone.name = "VisionCone"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = CONE_LENGTH * tan(deg_to_rad(CONE_HALF_ANGLE_DEG))
	mesh.height = CONE_LENGTH
	mesh.radial_segments = 24
	cone.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.9, 0.4, 0.05)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = mat
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cylinder axis is +Y; rotate -90deg so +Y maps to -Z (forward). Apex at the
	# eye, base CONE_LENGTH ahead.
	cone.position = Vector3(0.0, EYE_HEIGHT, -CONE_LENGTH * 0.5)
	cone.rotation.x = -PI * 0.5
	add_child(cone)
	_cone = cone


func _update_vision_cone() -> void:
	if _cone == null:
		return
	var alpha := 0.05
	if state == State.SUSPICIOUS:
		alpha = 0.08
	elif state == State.ALERTED:
		alpha = 0.12
	var mat := _cone.material_override as StandardMaterial3D
	if mat != null:
		var c := mat.albedo_color
		mat.albedo_color = Color(c.r, c.g, c.b, alpha)


# --- Procedural visuals ------------------------------------------------------

func _build_visuals() -> void:
	var skin := SKIN_TONES[randi() % SKIN_TONES.size()]
	var shirt := SHIRT_COLORS[randi() % SHIRT_COLORS.size()]
	var pants := PANTS_COLORS[randi() % PANTS_COLORS.size()]
	var hair := HAIR_COLORS[randi() % HAIR_COLORS.size()]
	var shoes := SHOE_COLORS[randi() % SHOE_COLORS.size()]

	# Slim cartoon body
	_add_capsule(self, Vector3(0.0, 1.1, 0.0), 0.15, 0.7, shirt, "Torso")
	_add_capsule(self, Vector3(-0.27, 1.075, 0.0), 0.055, 0.55, shirt, "ArmL")
	_add_capsule(self, Vector3(0.27, 1.075, 0.0), 0.055, 0.55, shirt, "ArmR")
	_add_capsule(self, Vector3(-0.11, 0.435, 0.0), 0.07, 0.63, pants, "LegL")
	_add_capsule(self, Vector3(0.11, 0.435, 0.0), 0.07, 0.63, pants, "LegR")
	# Head + hair + eyes
	_add_sphere(self, Vector3(0.0, 1.62, 0.0), 0.15, skin, "Head")
	var hair_mi := _add_sphere(self, Vector3(0.0, 1.68, 0.0), 0.155, hair, "Hair")
	hair_mi.scale = Vector3(1.05, 0.6, 1.05)
	_add_sphere(self, Vector3(-0.06, 1.63, -0.125), 0.028, Color(1.0, 1.0, 1.0), "EyeL")
	_add_sphere(self, Vector3(0.06, 1.63, -0.125), 0.028, Color(1.0, 1.0, 1.0), "EyeR")
	_add_sphere(self, Vector3(-0.06, 1.63, -0.15), 0.013, Color(0.1, 0.1, 0.12), "PupilL")
	_add_sphere(self, Vector3(0.06, 1.63, -0.15), 0.013, Color(0.1, 0.1, 0.12), "PupilR")
	# High-detail feet (group "feet")
	_build_foot(-0.11, shoes, "FootL")
	_build_foot(0.11, shoes, "FootR")


## One foot: ankle cylinder, foot box, 5 toe spheres, heel sphere, sole box,
## shoe details (stripe + tongue). Root node joins the "feet" group; a small
## Area3D trigger (also in "feet") lets the player's aim raycast hit the feet.
func _build_foot(x: float, shoe: Color, node_name: String) -> void:
	var foot := Node3D.new()
	foot.name = node_name
	foot.position = Vector3(x, 0.0, 0.02)
	foot.add_to_group("feet")
	add_child(foot)
	var sole := shoe.darkened(0.35)
	var accent := shoe.lightened(0.35)
	_add_cylinder(foot, Vector3(0.0, 0.07, 0.0), 0.045, 0.1, shoe, "Ankle")
	_add_box(foot, Vector3(0.0, 0.045, 0.05), Vector3(0.11, 0.07, 0.22), shoe, "FootBox")
	for i in 5:
		var tx := lerpf(-0.04, 0.04, float(i) / 4.0)
		_add_sphere(foot, Vector3(tx, 0.05, 0.16), 0.018, shoe, "Toe%d" % (i + 1))
	_add_sphere(foot, Vector3(0.0, 0.04, -0.06), 0.035, shoe, "Heel")
	_add_box(foot, Vector3(0.0, 0.012, 0.05), Vector3(0.12, 0.02, 0.24), sole, "Sole")
	_add_box(foot, Vector3(0.0, 0.082, 0.05), Vector3(0.11, 0.02, 0.06), accent, "Stripe")
	_add_box(foot, Vector3(0.0, 0.09, 0.1), Vector3(0.05, 0.03, 0.06), accent, "Tongue")
	var area := Area3D.new()
	area.name = "FootArea"
	area.add_to_group("feet")
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.14, 0.34)
	col.shape = shape
	col.position = Vector3(0.0, 0.05, 0.05)
	area.add_child(col)
	foot.add_child(area)


# --- Mesh helpers (flat-color StandardMaterial3D) ----------------------------

func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add_mesh(parent, m, pos, color, node_name)


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, node_name: String) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return _add_mesh(parent, m, pos, color, node_name)


func _add_capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _add_mesh(parent, m, pos, color, node_name)


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return _add_mesh(parent, m, pos, color, node_name)
