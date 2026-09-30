extends SceneTree
## Stealth smoke test (M2a): builds a level, spawns player + 1 NPC, and asserts
## the suspicion rule — NPCs only become SUSPICIOUS when they WITNESS weird
## behavior: zooming in on feet while visible, or a photo capture (noise with
## creep). Just being seen (or being close) does nothing. Movement noise makes
## the NPC investigate the sound position but adds no creep. Deferred to
## _process so autoloads (GameManager, NoiseSystem) are registered; the
## --script itself cannot reference autoload identifiers.

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

	# Park the NPC: stand still facing the player (yaw 0 faces -Z) so line of
	# sight stays true for the whole test regardless of wander randomness.
	npc._ai_state = NPC.AiState.IDLE
	npc._idle_time = 100.0
	npc._look_timer = 100.0
	npc._yaw = 0.0
	npc.rotation.y = 0.0

	# --- (a) seen normally: NPC stays IDLE, creep stays 0 ---
	player.is_zoomed = false
	player.is_aiming_at_feet = false
	await _wait_seconds(0.5)
	if npc.creep > 0.5:
		_fail("creep rose while just being seen (creep=%.2f)" % npc.creep)
	if npc.state != NPC.State.IDLE:
		_fail("NPC left IDLE while just being seen (state=%d)" % npc.state)

	# --- (b) zoomed + aiming at feet while visible: SUSPICIOUS + creep rises ---
	player.is_zoomed = true
	player.is_aiming_at_feet = true
	await _wait_seconds(0.1)
	if npc.state != NPC.State.SUSPICIOUS:
		_fail("NPC did not become SUSPICIOUS when zooming on feet (state=%d)" % npc.state)
	var before := npc.creep
	await _wait_seconds(0.5)
	var gained := npc.creep - before
	if gained < 2.0:
		_fail("creep did not rise while zoomed on feet (gained=%.2f)" % gained)

	# --- (c) hidden: the NPC must stop seeing the player (no gain) ---
	player.is_hidden = true
	var before_hidden := npc.creep
	await _wait_seconds(0.5)
	if npc.creep > before_hidden + 0.5:
		_fail("creep kept rising while hidden (creep=%.2f)" % npc.creep)

	# --- (d) movement noise: investigates the position but creep stays 0 ---
	# Player stays hidden so the NPC's per-frame last_seen_pos update (visible
	# player) cannot overwrite the noise position we assert on.
	npc.creep = 0.0
	npc.state = NPC.State.IDLE
	var noise_system := root.get_node("NoiseSystem")
	var noise_pos := npc.global_position + Vector3(2.0, 0.0, 0.0)
	noise_system.emit_noise(noise_pos, 6.0, 0.0)
	await _wait_seconds(0.1)
	if npc.creep > 0.5:
		_fail("movement noise raised creep (creep=%.2f)" % npc.creep)
	if npc.last_seen_pos.distance_to(noise_pos) > 0.5:
		_fail("NPC did not investigate the movement noise position (last_seen=%.2f,%.2f,%.2f)" % [npc.last_seen_pos.x, npc.last_seen_pos.y, npc.last_seen_pos.z])

	# --- (e) capture noise: creep rises (weird act) ---
	player.is_hidden = false
	var before_capture := npc.creep
	noise_system.emit_noise(npc.global_position, 6.0, 5.0)
	await _wait_seconds(0.1)
	if npc.creep <= before_capture:
		_fail("capture noise did not raise creep (creep=%.2f)" % npc.creep)

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
