class_name LevelBuilder
extends RefCounted
## Procedurally builds a Node3D level from a LevelDefinition (M1b).
## All props get solid StaticBody3D colliders that block raycasts.
## M2a: bushes also get a HidingSpot trigger (player can hide inside).
## M4: new decorative prop types + AmbientAnimator sine bob/sway for a few
## props per level (beach balls, umbrellas, flags, fountain water).

const WALL_THICKNESS := 0.2
const DOOR_WIDTH := 1.2
const DOOR_HEIGHT := 2.0
const WINDOW_SIZE := Vector3(0.8, 0.8, 0.05)
const VIGNETTE_SHADER := preload("res://shaders/vignette.gdshader")


static func build(def: LevelDefinition) -> Node3D:
	var level := Node3D.new()
	level.name = "Level"
	_build_ground(level, def)
	_build_sun(level, def)
	_build_ambient(level, def)
	_build_vignette(level, def)
	for prop in def.props:
		_build_prop(level, prop)
	return level


# --- Ground / lighting -------------------------------------------------------

static func _build_ground(parent: Node3D, def: LevelDefinition) -> void:
	var size := Vector3(def.ground_size.x, 0.2, def.ground_size.y)
	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(def.ground_color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0.0, -0.1, 0.0)  # top surface at y=0
	parent.add_child(body)


static func _build_sun(parent: Node3D, def: LevelDefinition) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.position = Vector3(0.0, 15.0, 0.0)
	sun.rotation_degrees = def.sun_rotation
	sun.light_color = def.sun_color
	sun.light_energy = def.sun_intensity
	parent.add_child(sun)


static func _build_ambient(parent: Node3D, def: LevelDefinition) -> void:
	var env := Environment.new()
	# M3a: per-level mood — solid background color, color ambient, bloom glow,
	# filmic tonemap, and optional subtle fog (vignette is a separate overlay).
	env.background_mode = Environment.BG_COLOR
	env.background_color = def.background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = def.ambient_color
	env.ambient_light_energy = 1.0
	env.glow_enabled = true
	env.glow_intensity = def.glow_intensity
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if def.fog_enabled:
		env.fog_enabled = true
		env.fog_light_color = def.fog_color
		env.fog_density = def.fog_density
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	parent.add_child(we)


## M3a: vignette post-process. Godot 4.7 removed Environment.vignette_* (a
## Godot 3 API), so the vignette is a fullscreen screen-space overlay: a
## CanvasLayer (layer 0, below the HUD) with a ColorRect running the vignette
## shader. Per-level intensity comes from def.vignette_intensity.
static func _build_vignette(parent: Node3D, def: LevelDefinition) -> void:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 0
	var rect := ColorRect.new()
	rect.name = "ColorRect"  # explicit name (Godot 4.7 auto-renames new nodes)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	mat.set_shader_parameter("intensity", def.vignette_intensity)
	rect.material = mat
	layer.add_child(rect)
	parent.add_child(layer)


# --- Prop dispatch -----------------------------------------------------------

## M4: props with bob/sway get wrapped in an AmbientAnimator (positioned at the
## prop's spot; the prop itself is built at local origin inside the animator).
static func _build_prop(parent: Node3D, prop: PropData) -> void:
	if prop.bob > 0.0 or prop.sway > 0.0:
		var anim := AmbientAnimator.new()
		anim.name = "Animated"
		anim.position = prop.position
		anim.bob_amplitude = prop.bob
		anim.sway_amplitude = prop.sway
		anim.phase = fmod(absf(prop.position.x) + absf(prop.position.z), TAU)
		parent.add_child(anim)
		var local := PropData.new()
		local.type = prop.type
		local.scale = prop.scale
		local.color = prop.color
		local.door_side = prop.door_side
		local.window_count = prop.window_count
		local.bob = prop.bob
		local.sway = prop.sway
		local.position = Vector3.ZERO
		_build_prop_inner(anim, local)
	else:
		_build_prop_inner(parent, prop)


static func _build_prop_inner(parent: Node3D, prop: PropData) -> void:
	match prop.type:
		PropData.PropType.CUBE:
			_add_box(parent, prop.position, prop.scale, prop.color, "Cube")
		PropData.PropType.SPHERE:
			_add_sphere(parent, prop.position, prop.scale, prop.color, "Sphere")
		PropData.PropType.CAPSULE:
			_add_capsule(parent, prop.position, prop.scale, prop.color, "Capsule")
		PropData.PropType.CYLINDER:
			_add_cylinder(parent, prop.position, prop.scale, prop.color, "Cylinder")
		PropData.PropType.PLANE:
			_add_plane(parent, prop.position, prop.scale, prop.color, "Plane")
		PropData.PropType.WALL:
			_add_box(parent, prop.position, prop.scale, prop.color, "Wall")
		PropData.PropType.PARTITION:
			_add_box(parent, prop.position, prop.scale, prop.color, "Partition")
		PropData.PropType.BUILDING, PropData.PropType.RESTROOM:
			_build_building(parent, prop)
		PropData.PropType.FENCE:
			_build_fence(parent, prop)
		PropData.PropType.KIOSK, PropData.PropType.SNACK_STAND, PropData.PropType.TICKET_BOOTH:
			_build_stand(parent, prop)
		PropData.PropType.LIFEGUARD_TOWER:
			_build_tower(parent, prop)
		PropData.PropType.BENCH:
			_build_bench(parent, prop)
		PropData.PropType.TABLE:
			_build_table(parent, prop)
		PropData.PropType.CHAIR:
			_build_chair(parent, prop)
		PropData.PropType.TREE:
			_build_tree(parent, prop)
		PropData.PropType.BUSH:
			_build_bush(parent, prop)
		PropData.PropType.UMBRELLA:
			_build_umbrella(parent, prop)
		PropData.PropType.LAMP_POST:
			_build_lamp_post(parent, prop)
		PropData.PropType.PLANTER:
			_build_planter(parent, prop)
		PropData.PropType.SIGN:
			_build_sign(parent, prop)
		PropData.PropType.ROCK:
			_build_rock(parent, prop)
		PropData.PropType.FLOWER:
			_build_flower(parent, prop)
		PropData.PropType.PATH_TILE:
			_build_path_tile(parent, prop)
		PropData.PropType.FOUNTAIN:
			_build_fountain(parent, prop)
		PropData.PropType.TRASH_CAN:
			_build_trash_can(parent, prop)
		PropData.PropType.TOWEL:
			_build_towel(parent, prop)
		PropData.PropType.COOLER:
			_build_cooler(parent, prop)
		PropData.PropType.BEACH_BALL:
			_build_beach_ball(parent, prop)
		PropData.PropType.PILLAR:
			_build_pillar(parent, prop)
		PropData.PropType.BOOTH:
			_build_booth(parent, prop)
		PropData.PropType.BAR:
			_build_bar(parent, prop)
		PropData.PropType.PICNIC_TABLE:
			_build_picnic_table(parent, prop)
		PropData.PropType.DUNE:
			_build_dune(parent, prop)
		PropData.PropType.FLAG:
			_build_flag(parent, prop)


# --- Compound props ----------------------------------------------------------

static func _build_building(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var t := WALL_THICKNESS
	var root := StaticBody3D.new()
	root.name = "Building"
	root.position = prop.position
	parent.add_child(root)

	var door := prop.door_side
	# Front wall (z = +d/2)
	if door == PropData.DoorSide.FRONT:
		_add_door_wall_x(root, Vector3(0.0, 0.0, d * 0.5), w, h, t, prop.color, "WallFront")
	else:
		_add_box(root, Vector3(0.0, h * 0.5, d * 0.5), Vector3(w, h, t), prop.color, "WallFront")
	# Back wall (z = -d/2)
	if door == PropData.DoorSide.BACK:
		_add_door_wall_x(root, Vector3(0.0, 0.0, -d * 0.5), w, h, t, prop.color, "WallBack")
	else:
		_add_box(root, Vector3(0.0, h * 0.5, -d * 0.5), Vector3(w, h, t), prop.color, "WallBack")
	# Left wall (x = -w/2)
	if door == PropData.DoorSide.LEFT:
		_add_door_wall_z(root, Vector3(-w * 0.5, 0.0, 0.0), d, h, t, prop.color, "WallLeft")
	else:
		_add_box(root, Vector3(-w * 0.5, h * 0.5, 0.0), Vector3(t, h, d), prop.color, "WallLeft")
	# Right wall (x = +w/2)
	if door == PropData.DoorSide.RIGHT:
		_add_door_wall_z(root, Vector3(w * 0.5, 0.0, 0.0), d, h, t, prop.color, "WallRight")
	else:
		_add_box(root, Vector3(w * 0.5, h * 0.5, 0.0), Vector3(t, h, d), prop.color, "WallRight")
	# Roof
	_add_box(root, Vector3(0.0, h + t * 0.5, 0.0), Vector3(w, t, d), prop.color, "Roof")
	# Windows
	_build_windows(root, prop, w, h, d, t)


## Door wall spanning the X axis (front/back walls): two full-height segments
## flanking a walkable gap + a lintel above the door. No collider in the gap.
static func _add_door_wall_x(parent: Node3D, center: Vector3, wall_width: float, wall_height: float, thickness: float, color: Color, node_name: String) -> void:
	var side_w := (wall_width - DOOR_WIDTH) * 0.5
	if side_w > 0.01:
		_add_box(parent, center + Vector3(-(wall_width + DOOR_WIDTH) * 0.25, wall_height * 0.5, 0.0), Vector3(side_w, wall_height, thickness), color, node_name + "L")
		_add_box(parent, center + Vector3((wall_width + DOOR_WIDTH) * 0.25, wall_height * 0.5, 0.0), Vector3(side_w, wall_height, thickness), color, node_name + "R")
	var lintel_h := wall_height - DOOR_HEIGHT
	if lintel_h > 0.01:
		_add_box(parent, center + Vector3(0.0, DOOR_HEIGHT + lintel_h * 0.5, 0.0), Vector3(DOOR_WIDTH, lintel_h, thickness), color, node_name + "Lintel")


## Door wall spanning the Z axis (left/right walls).
static func _add_door_wall_z(parent: Node3D, center: Vector3, wall_width: float, wall_height: float, thickness: float, color: Color, node_name: String) -> void:
	var side_w := (wall_width - DOOR_WIDTH) * 0.5
	if side_w > 0.01:
		_add_box(parent, center + Vector3(0.0, wall_height * 0.5, -(wall_width + DOOR_WIDTH) * 0.25), Vector3(thickness, wall_height, side_w), color, node_name + "L")
		_add_box(parent, center + Vector3(0.0, wall_height * 0.5, (wall_width + DOOR_WIDTH) * 0.25), Vector3(thickness, wall_height, side_w), color, node_name + "R")
	var lintel_h := wall_height - DOOR_HEIGHT
	if lintel_h > 0.01:
		_add_box(parent, center + Vector3(0.0, DOOR_HEIGHT + lintel_h * 0.5, 0.0), Vector3(thickness, lintel_h, DOOR_WIDTH), color, node_name + "Lintel")


static func _build_windows(root: Node3D, prop: PropData, w: float, h: float, d: float, t: float) -> void:
	if prop.window_count <= 0:
		return
	var win_color := prop.color.lightened(0.5)
	var win_y := minf(h * 0.55, 1.4)
	# Wall indices: 0=front, 1=back, 2=left, 3=right (door wall excluded).
	var walls: Array[int] = []
	if prop.door_side != PropData.DoorSide.FRONT:
		walls.append(0)
	if prop.door_side != PropData.DoorSide.BACK:
		walls.append(1)
	if prop.door_side != PropData.DoorSide.LEFT:
		walls.append(2)
	if prop.door_side != PropData.DoorSide.RIGHT:
		walls.append(3)
	if walls.is_empty():
		walls = [0, 1, 2, 3]
	for i in prop.window_count:
		var wall := walls[i % walls.size()]
		var frac := float(i) / float(prop.window_count)
		var pos := Vector3.ZERO
		var size := WINDOW_SIZE
		match wall:
			0:
				pos = Vector3(lerpf(-w * 0.5 + 0.6, w * 0.5 - 0.6, frac), win_y, d * 0.5 + 0.03)
			1:
				pos = Vector3(lerpf(-w * 0.5 + 0.6, w * 0.5 - 0.6, frac), win_y, -d * 0.5 - 0.03)
			2:
				pos = Vector3(-w * 0.5 - 0.03, win_y, lerpf(-d * 0.5 + 0.6, d * 0.5 - 0.6, frac))
				size = Vector3(0.05, 0.8, 0.8)
			3:
				pos = Vector3(w * 0.5 + 0.03, win_y, lerpf(-d * 0.5 + 0.6, d * 0.5 - 0.6, frac))
				size = Vector3(0.05, 0.8, 0.8)
		_add_box(root, pos, size, win_color, "Window")


static func _build_fence(parent: Node3D, prop: PropData) -> void:
	var length := prop.scale.x
	var height := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "Fence"
	root.position = prop.position
	parent.add_child(root)
	var post_count := maxi(2, int(floor(length / 2.0)) + 1)
	for i in post_count:
		var x := lerpf(-length * 0.5, length * 0.5, float(i) / float(post_count - 1))
		_add_box(root, Vector3(x, height * 0.5, 0.0), Vector3(0.1, height, 0.1), prop.color, "Post")
	_add_box(root, Vector3(0.0, height - 0.1, 0.0), Vector3(length, 0.08, 0.08), prop.color, "RailTop")
	_add_box(root, Vector3(0.0, height * 0.5, 0.0), Vector3(length, 0.08, 0.08), prop.color, "RailMid")


static func _build_stand(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Stand"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h * 0.35, 0.0), Vector3(w, h * 0.7, d), prop.color, "Body")
	_add_box(root, Vector3(0.0, h * 0.55, d * 0.5 + 0.15), Vector3(w * 0.9, 0.15, 0.3), prop.color.lightened(0.2), "Counter")
	_add_box(root, Vector3(0.0, h * 0.95, 0.0), Vector3(w * 1.1, 0.1, d * 1.1), prop.color.darkened(0.2), "Awning")


static func _build_tower(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Tower"
	root.position = prop.position
	parent.add_child(root)
	var leg_h := h * 0.55
	var leg_x := w * 0.5 - 0.15
	var leg_z := d * 0.5 - 0.15
	for corner in [[-leg_x, -leg_z], [leg_x, -leg_z], [-leg_x, leg_z], [leg_x, leg_z]]:
		_add_box(root, Vector3(corner[0], leg_h * 0.5, corner[1]), Vector3(0.15, leg_h, 0.15), prop.color, "Leg")
	_add_box(root, Vector3(0.0, leg_h, 0.0), Vector3(w, 0.15, d), prop.color, "Platform")
	_add_box(root, Vector3(0.0, h - 0.1, 0.0), Vector3(w * 1.2, 0.1, d * 1.2), prop.color.darkened(0.2), "Roof")


static func _build_bench(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Bench"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h * 0.5, 0.0), Vector3(w, 0.08, d), prop.color, "Seat")
	for z in [-d * 0.5 + 0.1, d * 0.5 - 0.1]:
		_add_box(root, Vector3(-w * 0.5 + 0.1, h * 0.25, z), Vector3(0.08, h * 0.5, 0.08), prop.color, "Leg")
		_add_box(root, Vector3(w * 0.5 - 0.1, h * 0.25, z), Vector3(0.08, h * 0.5, 0.08), prop.color, "Leg")
	_add_box(root, Vector3(0.0, h * 0.85, -d * 0.5), Vector3(w, h * 0.3, 0.06), prop.color, "Backrest")


static func _build_table(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Table"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h - 0.05, 0.0), Vector3(w, 0.1, d), prop.color, "Top")
	for x in [-w * 0.5 + 0.1, w * 0.5 - 0.1]:
		for z in [-d * 0.5 + 0.1, d * 0.5 - 0.1]:
			_add_box(root, Vector3(x, h * 0.4, z), Vector3(0.08, h * 0.8, 0.08), prop.color, "Leg")


static func _build_chair(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Chair"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h * 0.5, 0.0), Vector3(w, 0.06, d), prop.color, "Seat")
	for x in [-w * 0.5 + 0.05, w * 0.5 - 0.05]:
		for z in [-d * 0.5 + 0.05, d * 0.5 - 0.05]:
			_add_box(root, Vector3(x, h * 0.25, z), Vector3(0.05, h * 0.5, 0.05), prop.color, "Leg")
	_add_box(root, Vector3(0.0, h * 0.85, -d * 0.5), Vector3(w, h * 0.35, 0.05), prop.color, "Backrest")


static func _build_tree(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "Tree"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.4, 0.0), Vector3(0.3, h * 0.8, 0.3), Color(0.45, 0.3, 0.2), "Trunk")
	_add_sphere(root, Vector3(0.0, h * 0.85, 0.0), Vector3(h * 0.5, h * 0.4, h * 0.5), prop.color, "Foliage")


static func _build_bush(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Bush"
	root.position = prop.position
	parent.add_child(root)
	_add_sphere(root, Vector3.ZERO, prop.scale, prop.color, "Bush")
	_add_hiding_spot(root, prop)


## M2a: bushes get a HidingSpot trigger — the player can hide inside it with
## interact (F). Sized from the bush scale with a margin so the player can
## stand adjacent to the solid foliage and still be inside the trigger.
static func _add_hiding_spot(parent: Node3D, prop: PropData) -> void:
	var spot := HidingSpot.new()
	spot.name = "HidingSpot"
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = maxf(prop.scale.x, prop.scale.z) * 0.5 + 0.6
	col.shape = shape
	col.position = Vector3(0.0, 0.6, 0.0)
	spot.add_child(col)
	parent.add_child(spot)


static func _build_umbrella(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var r := prop.scale.x * 0.5
	var root := StaticBody3D.new()
	root.name = "Umbrella"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.5, 0.0), Vector3(0.08, h, 0.08), Color(0.6, 0.6, 0.6), "Pole")
	_add_sphere(root, Vector3(0.0, h, 0.0), Vector3(r * 2.0, r, r * 2.0), prop.color, "Canopy")


# --- M4 decorative props -----------------------------------------------------

static func _build_lamp_post(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "LampPost"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.5, 0.0), Vector3(0.12, h, 0.12), Color(0.25, 0.25, 0.28), "Pole")
	_add_sphere(root, Vector3(0.0, h, 0.0), Vector3(0.5, 0.35, 0.5), prop.color, "Lamp")


static func _build_planter(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Planter"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, 0.25, 0.0), Vector3(prop.scale.x, 0.5, prop.scale.z), prop.color, "Pot")
	_add_sphere(root, Vector3(0.0, 0.65, 0.0), Vector3(prop.scale.x * 0.7, 0.5, prop.scale.z * 0.7), Color(0.2, 0.55, 0.2), "Plant")


static func _build_sign(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "Sign"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.4, 0.0), Vector3(0.1, h * 0.8, 0.1), Color(0.4, 0.35, 0.3), "Post")
	_add_box(root, Vector3(0.0, h * 0.85, 0.0), Vector3(prop.scale.x, h * 0.3, 0.08), prop.color, "Board")


static func _build_rock(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Rock"
	root.position = prop.position
	parent.add_child(root)
	_add_sphere(root, Vector3(0.0, prop.scale.y * 0.4, 0.0), Vector3(prop.scale.x, prop.scale.y * 0.8, prop.scale.z), prop.color, "Rock")


static func _build_flower(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Flower"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, 0.2, 0.0), Vector3(0.05, 0.4, 0.05), Color(0.2, 0.5, 0.2), "Stem")
	_add_sphere(root, Vector3(0.0, 0.45, 0.0), Vector3(0.3, 0.25, 0.3), prop.color, "Bloom")


static func _build_path_tile(parent: Node3D, prop: PropData) -> void:
	_add_plane(parent, prop.position + Vector3(0.0, 0.02, 0.0), prop.scale, prop.color, "PathTile")


static func _build_fountain(parent: Node3D, prop: PropData) -> void:
	var r := prop.scale.x
	var root := StaticBody3D.new()
	root.name = "Fountain"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, 0.3, 0.0), Vector3(r, 0.6, r), prop.color, "Basin")
	_add_cylinder(root, Vector3(0.0, 0.8, 0.0), Vector3(r * 0.3, 0.6, r * 0.3), prop.color.darkened(0.25), "Pedestal")
	# M4: gently bobbing water disc.
	var anim := AmbientAnimator.new()
	anim.name = "WaterAnim"
	anim.bob_amplitude = 0.05
	anim.bob_speed = 2.2
	root.add_child(anim)
	_add_sphere(anim, Vector3(0.0, 0.62, 0.0), Vector3(r * 0.85, 0.1, r * 0.85), Color(0.35, 0.65, 0.95), "Water")


static func _build_trash_can(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "TrashCan"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.5, 0.0), Vector3(prop.scale.x, h, prop.scale.x), prop.color, "Can")
	_add_box(root, Vector3(0.0, h + 0.03, 0.0), Vector3(prop.scale.x * 0.9, 0.06, prop.scale.x * 0.9), prop.color.darkened(0.2), "Lid")


static func _build_towel(parent: Node3D, prop: PropData) -> void:
	_add_plane(parent, prop.position + Vector3(0.0, 0.02, 0.0), prop.scale, prop.color, "Towel")


static func _build_cooler(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Cooler"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, prop.scale.y * 0.5, 0.0), prop.scale, prop.color, "Cooler")
	_add_box(root, Vector3(0.0, prop.scale.y + 0.02, 0.0), Vector3(prop.scale.x * 0.8, 0.05, prop.scale.z * 0.8), prop.color.lightened(0.2), "Lid")


static func _build_beach_ball(parent: Node3D, prop: PropData) -> void:
	_add_sphere(parent, prop.position + Vector3(0.0, prop.scale.y * 0.5, 0.0), prop.scale, prop.color, "BeachBall")


static func _build_pillar(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Pillar"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, prop.scale.y * 0.5, 0.0), prop.scale, prop.color, "Pillar")
	_add_box(root, Vector3(0.0, prop.scale.y, 0.0), Vector3(prop.scale.x * 1.4, 0.15, prop.scale.x * 1.4), prop.color.darkened(0.15), "Capital")


static func _build_booth(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "Booth"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h - 0.05, 0.0), Vector3(w, 0.1, d), prop.color, "Table")
	for z in [-d * 0.5 + 0.1, d * 0.5 - 0.1]:
		_add_box(root, Vector3(0.0, h * 0.4, z), Vector3(0.08, h * 0.8, 0.08), prop.color, "Leg")
	for x in [-w * 0.5 - 0.35, w * 0.5 + 0.35]:
		_add_box(root, Vector3(x, h * 0.45, 0.0), Vector3(0.5, 0.08, d), prop.color.lightened(0.15), "Seat")
		_add_box(root, Vector3(x, h * 0.2, 0.0), Vector3(0.08, h * 0.4, d), prop.color.lightened(0.15), "SeatLeg")


static func _build_bar(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Bar"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, prop.scale.y * 0.5, 0.0), prop.scale, prop.color, "Counter")
	_add_box(root, Vector3(0.0, prop.scale.y + 0.1, 0.0), Vector3(prop.scale.x, 0.2, prop.scale.z * 0.6), prop.color.lightened(0.2), "Top")


static func _build_picnic_table(parent: Node3D, prop: PropData) -> void:
	var w := prop.scale.x
	var h := prop.scale.y
	var d := prop.scale.z
	var root := StaticBody3D.new()
	root.name = "PicnicTable"
	root.position = prop.position
	parent.add_child(root)
	_add_box(root, Vector3(0.0, h - 0.05, 0.0), Vector3(w, 0.1, d), prop.color, "Top")
	for x in [-w * 0.5 + 0.15, w * 0.5 - 0.15]:
		for z in [-d * 0.5 + 0.15, d * 0.5 - 0.15]:
			_add_box(root, Vector3(x, h * 0.4, z), Vector3(0.1, h * 0.8, 0.1), prop.color, "Leg")
	for x in [-w * 0.5 - 0.4, w * 0.5 + 0.4]:
		_add_box(root, Vector3(x, h * 0.4, 0.0), Vector3(0.35, 0.08, d), prop.color.lightened(0.15), "Bench")
		_add_box(root, Vector3(x, h * 0.2, 0.0), Vector3(0.08, h * 0.4, d), prop.color.lightened(0.15), "BenchLeg")


static func _build_dune(parent: Node3D, prop: PropData) -> void:
	var root := StaticBody3D.new()
	root.name = "Dune"
	root.position = prop.position
	parent.add_child(root)
	_add_sphere(root, Vector3(0.0, prop.scale.y * 0.5, 0.0), prop.scale, prop.color, "Dune")


static func _build_flag(parent: Node3D, prop: PropData) -> void:
	var h := prop.scale.y
	var root := StaticBody3D.new()
	root.name = "Flag"
	root.position = prop.position
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, h * 0.5, 0.0), Vector3(0.08, h, 0.08), Color(0.7, 0.7, 0.7), "Pole")
	_add_box(root, Vector3(0.0, h * 0.85, 0.0), Vector3(prop.scale.x, h * 0.3, 0.05), prop.color, "Flag")


# --- Primitive helpers (mesh + matching solid collider) ----------------------

static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size.x * 0.5
	sphere.height = size.y
	mesh.mesh = sphere
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = size.x * 0.5
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_cylinder(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = size.x * 0.5
	cyl.bottom_radius = size.x * 0.5
	cyl.height = size.y
	mesh.mesh = cyl
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = size.x * 0.5
	shape.height = size.y
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_capsule(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = size.x * 0.5
	cap.height = size.y
	mesh.mesh = cap
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = size.x * 0.5
	shape.height = size.y
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_plane(parent: Node3D, pos: Vector3, size: Vector3, color: Color, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.z)
	mesh.mesh = plane
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.05, size.z)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
