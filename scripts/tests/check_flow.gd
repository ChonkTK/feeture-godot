extends SceneTree
## M2c flow test: uses the GameManager autoload's own level (Beach, 14 NPCs,
## 2 targets) and asserts the full loop headless: (a) targets picked (count ==
## def.target_count, distinct names, flagged is_target); (b) photographing all
## targets -> state COMPLETE; (c) forcing creep 100 on a visible NPC -> state
## CAUGHT; (d) next_level() builds the next level (level_index increments, new
## level_root). Deferred to _process so autoloads are registered; the --script
## itself cannot reference autoload identifiers at compile time, so the state
## enum is re-declared here (values match GameManager.State).

enum State { BOOT, PLAYING, CAUGHT, COMPLETE }

var _started := false
var _failures: Array[String] = []


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var gm := root.get_node("GameManager")
	# Keep the auto-advance/auto-restart timers from firing mid-test.
	gm.advance_delay = 60.0
	await _wait_seconds(0.1)

	# Freeze the autoload player + all NPCs so test-set state persists.
	gm.player.set_physics_process(false)
	for npc in gm.npcs:
		npc.set_physics_process(false)

	# --- (a) targets picked ---
	var level_def: LevelDefinition = gm.current_level
	if gm.targets.size() != level_def.target_count:
		_fail("targets count %d != def.target_count %d" % [gm.targets.size(), level_def.target_count])
	var seen := {}
	for t in gm.targets:
		if not t.is_target:
			_fail("target %s not flagged is_target" % t.npc_name)
		if seen.has(t.npc_name):
			_fail("duplicate target name %s" % t.npc_name)
		seen[t.npc_name] = true

	# --- (b) photograph all targets -> COMPLETE ---
	for t in gm.targets:
		if not _capture_target(gm, t):
			_fail("could not capture target %s" % t.npc_name)
	if gm.state != State.COMPLETE:
		_fail("state %d != COMPLETE after all targets" % gm.state)
	if gm.targets_photographed.size() != level_def.target_count:
		_fail("targets_photographed %d != %d" % [gm.targets_photographed.size(), level_def.target_count])

	# --- (c) creep 100 on a visible NPC -> CAUGHT ---
	gm.restart_level()
	await _wait_seconds(0.1)
	gm.player.set_physics_process(false)
	for npc in gm.npcs:
		npc.set_physics_process(false)
	if not await _force_caught(gm):
		_fail("forcing creep 100 on a visible NPC did not reach CAUGHT")

	# --- (d) next_level() builds the next level ---
	var old_root: Node3D = gm.level_root
	var old_index: int = gm.level_index
	gm.next_level()
	if gm.level_index != (old_index + 1) % 4:
		_fail("level_index did not increment (%d -> %d)" % [old_index, gm.level_index])
	if gm.level_root == null or gm.level_root == old_root:
		_fail("next_level did not build a new level_root")
	if gm.current_level == null:
		_fail("current_level missing after next_level")
	if gm.state != State.PLAYING:
		_fail("state %d != PLAYING after next_level" % gm.state)

	_finish()


## Teleports the player 4m from the target's feet (trying 4 approach
## directions to dodge props), aims the camera down at the feet, fully zooms,
## and forces a capture. Returns true on success.
func _capture_target(gm: Node, npc: NPC) -> bool:
	var p: Node3D = gm.player
	var camera: Camera3D = p.get_node("Camera")
	var pc: Node = p.get_node("PhotoCapture")
	camera.fov = 10.0
	camera.rotation.x = -atan2(1.55, 4.0)
	var approaches := [
		[Vector3(0.0, 0.0, 1.0), 0.0],
		[Vector3(0.0, 0.0, -1.0), PI],
		[Vector3(1.0, 0.0, 0.0), PI * 0.5],
		[Vector3(-1.0, 0.0, 0.0), -PI * 0.5],
	]
	for a in approaches:
		var dir: Vector3 = a[0]
		var yaw: float = a[1]
		p.global_position = npc.global_position + dir * 4.0
		p.rotation.y = yaw
		pc.cooldown_remaining = 0.0
		if pc.try_capture():
			return true
	return false


## Places the player 5m from each NPC (4 directions), faces the NPC at the
## player, forces creep 100, and waits for the NPC's caught check. Returns
## true when GameManager reaches CAUGHT.
func _force_caught(gm: Node) -> bool:
	var p: Node3D = gm.player
	var approaches := [
		[Vector3(0.0, 0.0, 1.0), PI],
		[Vector3(0.0, 0.0, -1.0), 0.0],
		[Vector3(1.0, 0.0, 0.0), -PI * 0.5],
		[Vector3(-1.0, 0.0, 0.0), PI * 0.5],
	]
	for npc in gm.npcs:
		var n: NPC = npc
		n.set_physics_process(true)
		for a in approaches:
			var dir: Vector3 = a[0]
			var yaw: float = a[1]
			p.global_position = n.global_position + dir * 5.0
			# SUSPICIOUS NPCs face the player every frame (_face_point), so the
			# FOV check in _line_of_sight stays satisfied. Set both rotation.y
			# and the internal _yaw so the first physics frame already faces the
			# player (an IDLE NPC would otherwise overwrite rotation.y with its
			# wander _yaw and fail the FOV check).
			n.state = NPC.State.SUSPICIOUS
			n.rotation.y = yaw
			n._yaw = yaw
			n.creep = 100.0
			await _wait_seconds(0.15)
			if gm.state == State.CAUGHT:
				return true
		n.set_physics_process(false)
	return false


func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOW CHECK OK")
		quit(0)
	else:
		print("FLOW CHECK FAIL: " + "; ".join(_failures))
		quit(1)
