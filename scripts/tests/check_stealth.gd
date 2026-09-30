extends SceneTree
## Stealth smoke test (M2a): builds a level, spawns player + 1 NPC, and asserts
## the creep rule — creep rises ONLY when the NPC sees the player AND the player
## is zoomed in on feet. Also checks hiding breaks line of sight and noise
## raises creep. Deferred to _process so autoloads (GameManager, NoiseSystem)
## are registered; the --script itself cannot reference autoload identifiers.

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
	def.name = "StealthTest"
	def.ground_size = Vector2(40.0, 40.0)
	var level: Node3D = LevelBuilder.build(def)
	root.add_child(level)

	# --- Spawn player + 1 NPC (player 10m in front of the NPC's initial facing) ---
	var player_scene: PackedScene = load(PLAYER_SCENE)
	var npc_scene: PackedScene = load(NPC_SCENE)
	if player_scene == null or npc_scene == null:
		_fail("could not load player/npc scenes")
		_finish()
		return
	var player = player_scene.instantiate()
	player.position = Vector3(0.0, 0.0, -18.0)
	level.add_child(player)
	var npc: NPC = npc_scene.instantiate()
	npc.setup(Vector3(0.0, 0.0, -8.0), Rect2(-20.0, -20.0, 40.0, 40.0))
	npc.player_ref = player
	level.add_child(npc)

	# Freeze the player's per-frame controller so test-set state persists.
	player.set_physics_process(false)

	# --- (a) seen normally: creep must NOT rise, but the NPC stares ---
	player.is_zoomed = false
	player.is_aiming_at_feet = false
	await _wait_seconds(0.5)
	if npc.creep > 0.5:
		_fail("creep rose while just being seen (creep=%.2f)" % npc.creep)
	if npc.state != NPC.State.SUSPICIOUS:
		_fail("NPC did not become SUSPICIOUS when seeing the player (state=%d)" % npc.state)

	# --- (b) zoomed + aiming at feet while visible: creep MUST rise ---
	player.is_zoomed = true
	player.is_aiming_at_feet = true
	var before := npc.creep
	await _wait_seconds(0.5)
	var gained := npc.creep - before
	if gained < 2.0:
		_fail("creep did not rise while zoomed on feet (gained=%.2f)" % gained)

	# --- (c) hidden: the NPC must stop seeing the player (no gain, then decay) ---
	player.is_hidden = true
	var before_hidden := npc.creep
	await _wait_seconds(0.5)
	if npc.creep > before_hidden + 0.5:
		_fail("creep kept rising while hidden (creep=%.2f)" % npc.creep)
	await _wait_seconds(2.5)
	if npc.creep >= before_hidden:
		_fail("creep did not decay while hidden (creep=%.2f)" % npc.creep)

	# --- (d) noise near the NPC raises its creep ---
	player.is_hidden = false
	player.is_zoomed = false
	player.is_aiming_at_feet = false
	var before_noise := npc.creep
	var noise_system := root.get_node("NoiseSystem")
	noise_system.emit_noise(npc.global_position, 6.0, 10.0)
	await _wait_seconds(0.1)
	if npc.creep <= before_noise:
		_fail("noise did not raise creep (creep=%.2f)" % npc.creep)

	_finish()


## Waits in game time (robust to uncapped headless frame rates).
func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("STEALTH CHECK OK")
		quit(0)
	else:
		print("STEALTH CHECK FAIL: " + "; ".join(_failures))
		quit(1)
