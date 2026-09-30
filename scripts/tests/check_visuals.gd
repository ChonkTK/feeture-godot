extends SceneTree
## M3a visual test: builds a level, instantiates an NPC, and asserts:
##  - every NPC body mesh uses a ShaderMaterial with the toon shader
##    (feet slightly glossier via the glossy uniform; the translucent
##    VisionCone intentionally stays StandardMaterial3D and is skipped);
##  - the level root has a WorldEnvironment with glow enabled, filmic
##    tonemap, vignette and a BG_COLOR background;
##  - all 4 level moods build with glow and distinct background colors.

var _checked := false
var _failures: Array[String] = []


func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true
	_run()
	return false


func _run() -> void:
	var toon: Shader = load("res://shaders/toon.gdshader")
	if toon == null:
		_fail("toon shader failed to load")
		_finish()
		return

	var def := BeachLevel.create()
	var level: Node3D = LevelBuilder.build(def)
	root.add_child(level)

	var npc_scene: PackedScene = load("res://scenes/npc/npc.tscn")
	if npc_scene == null:
		_fail("npc scene failed to load")
		_finish()
		return
	var npc: NPC = npc_scene.instantiate()
	level.add_child(npc)
	npc.set_physics_process(false)

	var body_count := 0
	var foot_count := 0
	for mi in _mesh_instances(npc):
		if mi.name == "VisionCone":
			continue  # translucent effect cone, intentionally StandardMaterial3D
		var mat := mi.material_override
		if not (mat is ShaderMaterial):
			_fail("mesh %s: material is %s, expected ShaderMaterial" % [mi.name, mat])
			continue
		var sm := mat as ShaderMaterial
		if sm.shader != toon:
			_fail("mesh %s: shader is not toon.gdshader" % mi.name)
			continue
		body_count += 1
		var glossy := float(sm.get_shader_parameter("glossy"))
		if _is_foot_mesh(mi):
			foot_count += 1
			if glossy <= 0.0:
				_fail("foot mesh %s: glossy not set (got %f)" % [mi.name, glossy])
		elif glossy > 0.0:
			_fail("body mesh %s: glossy should be 0 (got %f)" % [mi.name, glossy])
	if body_count == 0:
		_fail("no toon-shaded meshes found on NPC")
	if foot_count == 0:
		_fail("no foot meshes found on NPC")

	var we := level.get_node_or_null("WorldEnvironment")
	if we == null:
		_fail("level root missing WorldEnvironment")
	else:
		var env: Environment = (we as WorldEnvironment).environment
		if env == null:
			_fail("WorldEnvironment has no Environment")
		else:
			if not env.glow_enabled:
				_fail("glow not enabled")
			if env.tonemap_mode != Environment.TONE_MAPPER_FILMIC:
				_fail("tonemap_mode %d != FILMIC" % env.tonemap_mode)
			if env.background_mode != Environment.BG_COLOR:
				_fail("background_mode %d != BG_COLOR" % env.background_mode)
	_check_vignette(level, def)

	# Per-level moods: all 4 levels build with glow + distinct backgrounds.
	var seen_bg := {}
	for ldef in [BeachLevel.create(), SubwayLevel.create(), RestaurantLevel.create(), ParkLevel.create()]:
		var l: Node3D = LevelBuilder.build(ldef)
		root.add_child(l)
		var lwe := l.get_node_or_null("WorldEnvironment")
		if lwe == null:
			_fail("%s: missing WorldEnvironment" % ldef.name)
		else:
			var lenv: Environment = (lwe as WorldEnvironment).environment
			if lenv == null or not lenv.glow_enabled:
				_fail("%s: glow not enabled" % ldef.name)
			else:
				seen_bg[lenv.background_color.to_html(false)] = ldef.name
		l.free()
	if seen_bg.size() < 4:
		_fail("level background colors not distinct (%d unique)" % seen_bg.size())

	_finish()


## Godot 4.7 removed Environment.vignette_*; the vignette is a fullscreen
## CanvasLayer overlay ("Vignette") with a ColorRect running the vignette
## shader at the level's intensity.
func _check_vignette(level: Node3D, def: LevelDefinition) -> void:
	var layer := level.get_node_or_null("Vignette")
	if layer == null or not (layer is CanvasLayer):
		_fail("level root missing Vignette CanvasLayer")
		return
	var rect := layer.get_node_or_null("ColorRect")
	if rect == null or not (rect is ColorRect):
		_fail("Vignette layer missing ColorRect")
		return
	var mat := (rect as ColorRect).material
	if not (mat is ShaderMaterial):
		_fail("Vignette ColorRect material is not ShaderMaterial")
		return
	var vig_shader: Shader = load("res://shaders/vignette.gdshader")
	if (mat as ShaderMaterial).shader != vig_shader:
		_fail("Vignette ColorRect shader is not vignette.gdshader")
		return
	var intensity := float((mat as ShaderMaterial).get_shader_parameter("intensity"))
	if intensity <= 0.0:
		_fail("Vignette intensity not set (got %f)" % intensity)
	if absf(intensity - def.vignette_intensity) > 0.001:
		_fail("Vignette intensity %f != def %f" % [intensity, def.vignette_intensity])


func _is_foot_mesh(mi: MeshInstance3D) -> bool:
	var p := mi.get_parent()
	return p != null and (p.name == "FootL" or p.name == "FootR")


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append(child)
		out.append_array(_mesh_instances(child))
	return out


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("VISUALS CHECK OK")
		quit(0)
	else:
		print("VISUALS CHECK FAIL: " + "; ".join(_failures))
		quit(1)
