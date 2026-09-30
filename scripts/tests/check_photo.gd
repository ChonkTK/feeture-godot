extends SceneTree
## Photo smoke test (M2b): builds a level, spawns player + 1 NPC, positions the
## player 4m in front of the NPC's feet, aims the camera at the feet, forces a
## capture via PhotoCapture.try_capture(), and asserts: a record was added with
## score 0..100 and rank in {S,A,B,C}; the PNG exists in user://photos/; the
## photographed NPC's creep increased. Deferred to _process so autoloads
## (PhotoAlbum, NoiseSystem, GameManager) are registered; the --script itself
## cannot reference autoload identifiers at compile time.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const NPC_SCENE := "res://scenes/npc/npc.tscn"

var _started := false
var _failures: Array[String] = []


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	# --- Build a minimal level (ground + sun + env, no props) ---
	var def := LevelDefinition.new()
	def.name = "PhotoTest"
	def.ground_size = Vector2(40.0, 40.0)
	var level: Node3D = LevelBuilder.build(def)
	root.add_child(level)

	# --- Spawn player 4m in front of the NPC (feet in view) ---
	var player_scene: PackedScene = load(PLAYER_SCENE)
	var npc_scene: PackedScene = load(NPC_SCENE)
	if player_scene == null or npc_scene == null:
		_fail("could not load player/npc scenes")
		_finish()
		return
	# Offset from the origin: the GameManager autoload's own player spawns at
	# ZERO in its Beach level, and an overlapping body would block the ray.
	var player = player_scene.instantiate()
	player.position = Vector3(0.0, 0.0, 14.0)
	level.add_child(player)
	var npc: NPC = npc_scene.instantiate()
	npc.setup(Vector3(0.0, 0.0, 10.0), Rect2(-20.0, -20.0, 40.0, 40.0))
	npc.player_ref = player
	level.add_child(npc)

	# Freeze both controllers so test-set state persists and the NPC cannot
	# wander into the 2.5m alert range (which would trigger a catch).
	player.set_physics_process(false)
	npc.set_physics_process(false)

	# Aim the camera at the NPC's feet (4m ahead, ~1.55m below the eye) and
	# fully zoom in (FOV 10).
	var camera: Camera3D = player.get_node("Camera")
	camera.rotation.x = -atan2(1.55, 4.0)
	camera.fov = 10.0

	# Let the physics server settle the new bodies' transforms (a raycast in
	# the same frame as add_child hits stale colliders).
	await _wait_seconds(0.1)

	var photo_capture = player.get_node("PhotoCapture")
	var album := root.get_node("PhotoAlbum")
	var before_creep := npc.creep
	var before_count: int = album.count

	var ok: bool = photo_capture.try_capture()
	if not ok:
		_fail("try_capture returned false")
		_finish()
		return

	# --- (a) record added with score 0..100 and rank in {S,A,B,C} ---
	if album.count != before_count + 1:
		_fail("no photo record added (count=%d)" % album.count)
	var record: Dictionary = album.records[album.records.size() - 1]
	var score: int = record["score"]
	var rank: String = record["rank"]
	if score < 0 or score > 100:
		_fail("score out of range 0..100 (score=%d)" % score)
	if not rank in ["S", "A", "B", "C"]:
		_fail("bad rank %s" % rank)

	# --- (b) PNG exists in user://photos/ ---
	var path: String = photo_capture.last_result.get("path", "")
	if path.is_empty() or not FileAccess.file_exists(path):
		_fail("PNG not saved (%s)" % path)

	# --- (c) photographed NPC's creep increased ---
	if npc.creep <= before_creep:
		_fail("creep did not increase after photo (creep=%.2f)" % npc.creep)

	_finish()


func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("PHOTO CHECK OK")
		quit(0)
	else:
		print("PHOTO CHECK FAIL: " + "; ".join(_failures))
		quit(1)
