extends SceneTree
## Smoke test (M1a): load + instantiate player scene, verify structure and input map.
## Player load is deferred to _process so autoload globals (Settings) are registered.

const EXPECTED_ACTIONS := [
	"move_left", "move_right", "move_forward", "move_back",
	"crouch", "sprint", "lean_left", "lean_right",
	"zoom", "capture", "interact", "pause", "album",
]

var _checked := false


func _init() -> void:
	for action in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("Missing input action: " + action)
			quit(1)
			return


func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true

	var scene: PackedScene = load("res://scenes/player/player.tscn")
	if scene == null:
		push_error("Failed to load res://scenes/player/player.tscn")
		quit(1)
		return true
	var player := scene.instantiate()
	if player == null:
		push_error("Failed to instantiate player scene")
		quit(1)
		return true
	if not player is CharacterBody3D:
		push_error("Player root is not CharacterBody3D")
		player.free()
		quit(1)
		return true
	var cam := player.get_node_or_null("Camera")
	if cam == null or not cam is Camera3D:
		push_error("Player has no Camera3D child")
		player.free()
		quit(1)
		return true

	print("PLAYER CHECK OK")
	player.free()
	quit(0)
	return true
