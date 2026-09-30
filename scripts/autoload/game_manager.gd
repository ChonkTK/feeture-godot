extends Node
## GameManager autoload (M1c): owns game state, level lifecycle, player and NPCs.
## Replaces the M0 placeholder. Builds level 0 (Beach) on boot, spawns the
## player and NPCs from the level definition. M2 uses next_level()/restart_level().
## M2a: handle_caught() and global_creep (max of NPC creeps).
## M2b: prints a line when the player's PhotoCapture component takes a photo.
## M2c: picks 2-3 named target NPCs per level; photographing all targets wins
## (COMPLETE -> auto next_level), getting caught loses (CAUGHT -> auto
## restart_level). Emits photo_captured / state_changed / target_photographed
## for the HUD.

enum State { BOOT, PLAYING, CAUGHT, COMPLETE }

signal photo_captured(npc_name: String, score: int, rank: String)
signal state_changed(new_state: int)
signal target_photographed(npc_name: String)

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const NPC_SCENE := "res://scenes/npc/npc.tscn"
const LEVEL_COUNT := 4
const ADVANCE_DELAY := 2.0

var state: State = State.BOOT
var level_index: int = 0
var current_level: LevelDefinition = null
var level_root: Node3D = null
var player: Node3D = null
var npcs: Array = []
var targets: Array = []                 # M2c: NPC nodes flagged is_target
var targets_photographed: Array[String] = []  # M2c: names of photographed targets
var global_creep: float = 0.0           # M2c: max NPC creep, refreshed each frame
var advance_delay: float = ADVANCE_DELAY  # M2c: auto-advance delay (tests override)
var hud: Node = null

var _advance_timer: SceneTreeTimer = null


func _ready() -> void:
	_load_level(level_index)
	state = State.PLAYING
	_build_hud()
	if "--smoke" in OS.get_cmdline_user_args():
		_smoke_test()


func _process(_delta: float) -> void:
	global_creep = _compute_global_creep()


func _load_level(index: int) -> void:
	clear_level()
	current_level = _create_level(index)
	level_root = LevelBuilder.build(current_level)
	add_child(level_root)
	_spawn_player()
	_spawn_npcs()
	_pick_targets()


func _create_level(index: int) -> LevelDefinition:
	match index:
		0:
			return BeachLevel.create()
		1:
			return SubwayLevel.create()
		2:
			return RestaurantLevel.create()
		3:
			return ParkLevel.create()
	return BeachLevel.create()


func _spawn_player() -> void:
	var scene: PackedScene = load(PLAYER_SCENE)
	if scene == null:
		push_error("GameManager: failed to load player scene")
		return
	player = scene.instantiate() as Node3D
	player.position = Vector3.ZERO
	level_root.add_child(player)
	# M2b: hook the player's photo capture so we can score/win.
	var pc := player.get_node_or_null("PhotoCapture")
	if pc != null and pc.has_signal("photo_captured"):
		pc.photo_captured.connect(_on_photo_captured)


func _spawn_npcs() -> void:
	var scene: PackedScene = load(NPC_SCENE)
	if scene == null:
		push_error("GameManager: failed to load NPC scene")
		return
	var gs := current_level.ground_size
	var bounds := Rect2(-gs.x * 0.5, -gs.y * 0.5, gs.x, gs.y)
	for spawn in current_level.npc_spawns:
		var npc: NPC = scene.instantiate() as NPC
		npc.setup(spawn, bounds)
		level_root.add_child(npc)
		npcs.append(npc)


## M2c: shuffle the NPCs and flag def.target_count of them (distinct names) as
## photo targets. Stores the NPC nodes in `targets`.
func _pick_targets() -> void:
	targets.clear()
	targets_photographed.clear()
	var pool := npcs.duplicate()
	pool.shuffle()
	var want := current_level.target_count
	var seen := {}
	for npc in pool:
		if targets.size() >= want:
			break
		if seen.has(npc.npc_name):
			continue
		seen[npc.npc_name] = true
		npc.is_target = true
		targets.append(npc)


## Frees the current level root (and everything under it: player, NPCs, props).
func clear_level() -> void:
	if level_root != null:
		level_root.queue_free()
		level_root = null
	npcs.clear()
	targets.clear()
	targets_photographed.clear()
	player = null


## M2: advance to the next level definition (Beach -> Subway -> Restaurant ->
## Park, then loop).
func next_level() -> void:
	level_index = (level_index + 1) % LEVEL_COUNT
	_load_level(level_index)
	state = State.PLAYING
	state_changed.emit(state)


## M2: rebuild the current level.
func restart_level() -> void:
	_load_level(level_index)
	state = State.PLAYING
	state_changed.emit(state)


## M2a/M2c: the player got caught (creep 100 while visible, or ALERTED within
## 3m). CAUGHT, then auto-restart after a short delay.
func handle_caught() -> void:
	if state == State.CAUGHT:
		return
	state = State.CAUGHT
	state_changed.emit(state)
	print("CAUGHT: the player was caught!")
	_advance_timer = get_tree().create_timer(advance_delay)
	_advance_timer.timeout.connect(_on_advance_timeout)


## M2c: all targets photographed — COMPLETE, then auto-advance after a delay.
func _complete_level() -> void:
	if state == State.COMPLETE:
		return
	state = State.COMPLETE
	state_changed.emit(state)
	print("LEVEL COMPLETE")
	_advance_timer = get_tree().create_timer(advance_delay)
	_advance_timer.timeout.connect(_on_advance_timeout)


func _on_advance_timeout() -> void:
	match state:
		State.COMPLETE:
			next_level()
		State.CAUGHT:
			restart_level()


## M2a: global creep = max of all NPC creeps (0 when none).
func _compute_global_creep() -> float:
	var max_creep := 0.0
	for npc in npcs:
		if npc != null and npc.creep > max_creep:
			max_creep = npc.creep
	return max_creep


## M2b/M2c: a photo was taken — print it, re-emit for the HUD, and if it was a
## target, mark it; when all targets are photographed the level is COMPLETE.
func _on_photo_captured(npc_name: String, score: int, rank: String) -> void:
	print("PHOTO: %s — %d pts (%s)" % [npc_name, score, rank])
	photo_captured.emit(npc_name, score, rank)
	if state != State.PLAYING:
		return
	if not _is_target_name(npc_name):
		return
	if npc_name in targets_photographed:
		return
	targets_photographed.append(npc_name)
	target_photographed.emit(npc_name)
	if targets_photographed.size() >= targets.size():
		_complete_level()


func _is_target_name(npc_name: String) -> bool:
	for t in targets:
		if t.npc_name == npc_name:
			return true
	return false


## M2c: build the HUD (CanvasLayer built in code) as a child of GameManager so
## it exists in every mode (game + headless tests).
func _build_hud() -> void:
	var script := load("res://scripts/ui/hud.gd")
	if script == null:
		push_error("GameManager: failed to load HUD script")
		return
	hud = script.new()
	add_child(hud)


func _smoke_test() -> void:
	for i in 60:
		await get_tree().process_frame
	var reason := ""
	if player == null:
		reason = "player missing"
	elif npcs.size() < 8 or npcs.size() > 10:
		reason = "npc count %d out of range 8..10" % npcs.size()
	elif current_level == null or level_root == null:
		reason = "level missing"
	if reason.is_empty():
		print("SMOKE OK: player=%s npcs=%d level=%s" % [player != null, npcs.size(), current_level.name])
		get_tree().quit(0)
	else:
		print("SMOKE FAIL: " + reason)
		get_tree().quit(1)
