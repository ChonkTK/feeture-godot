extends Node
## GameManager autoload (M1c): owns game state, level lifecycle, player and NPCs.
## Replaces the M0 placeholder. Builds level 0 (Beach) on boot, spawns the
## player and NPCs from the level definition. M2 uses next_level()/restart_level().
## M2a: handle_caught() and global_creep() (max of NPC creeps).

enum State { BOOT, PLAYING, CAUGHT, COMPLETE }

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const NPC_SCENE := "res://scenes/npc/npc.tscn"

var state: State = State.BOOT
var level_index: int = 0
var current_level: LevelDefinition = null
var level_root: Node3D = null
var player: Node3D = null
var npcs: Array = []


func _ready() -> void:
	_load_level(level_index)
	state = State.PLAYING
	if "--smoke" in OS.get_cmdline_user_args():
		_smoke_test()


func _load_level(index: int) -> void:
	clear_level()
	current_level = _create_level(index)
	level_root = LevelBuilder.build(current_level)
	add_child(level_root)
	_spawn_player()
	_spawn_npcs()


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


## Frees the current level root (and everything under it: player, NPCs, props).
func clear_level() -> void:
	if level_root != null:
		level_root.queue_free()
		level_root = null
	npcs.clear()
	player = null


## M2: advance to the next level definition.
func next_level() -> void:
	level_index = (level_index + 1) % 4
	_load_level(level_index)
	state = State.PLAYING


## M2: rebuild the current level.
func restart_level() -> void:
	_load_level(level_index)
	state = State.PLAYING


## M2a: the player got caught (creep 100 while visible, or ALERTED within 3m).
## Prints for now; a HUD hook comes in a later milestone.
func handle_caught() -> void:
	if state == State.CAUGHT:
		return
	state = State.CAUGHT
	print("CAUGHT: the player was caught!")


## M2a: global creep = max of all NPC creeps (0 when none).
func global_creep() -> float:
	var max_creep := 0.0
	for npc in npcs:
		if npc != null and npc.creep > max_creep:
			max_creep = npc.creep
	return max_creep


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
