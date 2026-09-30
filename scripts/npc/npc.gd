class_name NPC
extends CharacterBody3D
## Wander NPC (M1c): procedural cartoon body with high-detail feet, random
## identity, and simple wander AI (walk to random point, idle pause, look around).

const WALK_SPEED := 1.5
const GRAVITY := -20.0
const ARRIVE_DIST := 0.35

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

enum AiState { IDLE, WALKING }

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


func _ready() -> void:
	npc_name = NAMES[randi() % NAMES.size()]
	_build_visuals()
	_pick_target()
	_ai_state = AiState.WALKING


## Called by GameManager before add_child: sets spawn point and wander bounds.
func setup(spawn: Vector3, level_bounds: Rect2) -> void:
	bounds = level_bounds
	position = spawn
	_pick_target()
	_ai_state = AiState.WALKING


func _physics_process(delta: float) -> void:
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
			var to_target := _target - global_position
			to_target.y = 0.0
			if to_target.length() < ARRIVE_DIST:
				_idle_time = randf_range(1.0, 3.0)
				_ai_state = AiState.IDLE
			else:
				var dir := to_target.normalized()
				_yaw = lerp_angle(_yaw, atan2(-dir.x, -dir.z), 5.0 * delta)
				rotation.y = _yaw
				velocity.x = dir.x * WALK_SPEED
				velocity.z = dir.z * WALK_SPEED
	velocity.y += GRAVITY * delta
	move_and_slide()


func _pick_target() -> void:
	_target = Vector3(
		randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
		0.0,
		randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
	)


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
## shoe details (stripe + tongue). Root node joins the "feet" group.
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
