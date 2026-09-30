extends SceneTree
## Smoke test (M1b/M4): build each level via LevelBuilder in ISOLATION (one
## level in the world at a time, so raycasts can't hit other levels' colliders),
## verify structure (ground + sun + world env + props + spawns), that building
## door gaps are walkable (raycast from inside passes through the gap), and that
## the world is dense: >= 25 props and >= 10 NPC spawns per level.

var _checked := false
var _results: Array[String] = []
var _failures := 0


func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true

	var defs := [
		BeachLevel.create(),
		SubwayLevel.create(),
		RestaurantLevel.create(),
		ParkLevel.create(),
	]
	for def in defs:
		var level: Node3D = LevelBuilder.build(def)
		root.add_child(level)
		var prop_count := _count_prop_roots(level)
		if level.get_node_or_null("Ground") == null:
			push_error(def.name + ": missing Ground")
			_failures += 1
		if level.get_node_or_null("Sun") == null:
			push_error(def.name + ": missing Sun")
			_failures += 1
		if level.get_node_or_null("WorldEnvironment") == null:
			push_error(def.name + ": missing WorldEnvironment")
			_failures += 1
		if prop_count < 25:
			push_error(def.name + ": only %d props (need >= 25)" % prop_count)
			_failures += 1
		if def.npc_spawns.size() < 10:
			push_error(def.name + ": only %d npc_spawns (need >= 10)" % def.npc_spawns.size())
			_failures += 1
		if not _check_door_gap(level, def):
			_failures += 1
		_results.append("%s=%d" % [def.name, prop_count])
		level.free()

	print("LEVELS CHECK OK: " + " ".join(_results))
	if _failures > 0:
		quit(1)
	else:
		quit(0)
	return true


## Casts a ray from the building center outward through the door at y=1.0.
## If the gap is open the first hit is beyond the door wall (or nothing);
## if the door wall were solid the first hit would be the wall itself.
func _check_door_gap(level: Node3D, def: LevelDefinition) -> bool:
	for prop in def.props:
		if prop.door_side == PropData.DoorSide.NONE:
			continue
		if prop.type != PropData.PropType.BUILDING and prop.type != PropData.PropType.RESTROOM:
			continue
		var w := prop.scale.x
		var d := prop.scale.z
		var from := prop.position + Vector3(0.0, 1.0, 0.0)
		var to := Vector3.ZERO
		var door_dist := 0.0
		match prop.door_side:
			PropData.DoorSide.FRONT:
				to = prop.position + Vector3(0.0, 1.0, d * 0.5 + 6.0)
				door_dist = d * 0.5
			PropData.DoorSide.BACK:
				to = prop.position + Vector3(0.0, 1.0, -d * 0.5 - 6.0)
				door_dist = d * 0.5
			PropData.DoorSide.LEFT:
				to = prop.position + Vector3(-w * 0.5 - 6.0, 1.0, 0.0)
				door_dist = w * 0.5
			PropData.DoorSide.RIGHT:
				to = prop.position + Vector3(w * 0.5 + 6.0, 1.0, 0.0)
				door_dist = w * 0.5
		var space := level.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue  # nothing hit — gap open, fine
		var hit_dist := from.distance_to(result.position)
		if hit_dist < door_dist + 0.4:
			push_error("%s: door gap blocked (door_side=%d, hit_dist=%.2f)" % [def.name, prop.door_side, hit_dist])
			return false
	return true


## Counts prop roots: direct StaticBody3D children of the level root (minus
## Ground), plus the StaticBody3D root of each AmbientAnimator-wrapped prop.
func _count_prop_roots(level: Node3D) -> int:
	var count := 0
	for child in level.get_children():
		if child is StaticBody3D and child.name != "Ground":
			count += 1
		elif child is AmbientAnimator:
			for sub in child.get_children():
				if sub is StaticBody3D:
					count += 1
	return count
