extends Node
## Settings autoload: mouse sensitivity, invert Y, volume levels, and
## InputMap bindings for the gameplay actions. Loads from / saves to
## user://settings.cfg via ConfigFile. M3c: the same ConfigFile persists
## custom InputMap bindings (events serialized with var_to_str) and restores
## them on startup; reset_input_bindings() restores the project defaults.

const SETTINGS_PATH := "user://settings.cfg"
const BINDINGS_SECTION := "input_bindings"

## Gameplay actions exposed in the remap UI (order = display order).
const GAMEPLAY_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_forward", "move_back",
	"crouch", "sprint", "lean_left", "lean_right",
	"zoom", "capture", "interact", "pause", "album",
]

var mouse_sensitivity: float = 0.003
var invert_y: bool = false
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0


func _ready() -> void:
	load_settings()
	load_input_bindings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	invert_y = cfg.get_value("input", "invert_y", invert_y)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "invert_y", invert_y)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	_save_bindings(cfg)
	cfg.save(SETTINGS_PATH)


## Applies saved InputMap bindings (if any) for the gameplay actions.
func load_input_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for action in GAMEPLAY_ACTIONS:
		if not cfg.has_section_key(BINDINGS_SECTION, action):
			continue
		var strs: PackedStringArray = cfg.get_value(BINDINGS_SECTION, action, PackedStringArray())
		InputMap.action_erase_events(action)
		for s in strs:
			var ev = str_to_var(s)
			if ev is InputEvent:
				InputMap.action_add_event(action, ev)


## Restores the default bindings for all gameplay actions and persists them.
func reset_input_bindings() -> void:
	for action in GAMEPLAY_ACTIONS:
		InputMap.action_erase_events(action)
		for ev in default_events(action):
			InputMap.action_add_event(action, ev)
	save_settings()


## Default InputEvents for an action (matches project.godot [input]).
func default_events(action: String) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	match action:
		"move_left":
			out.append(_key(KEY_A))
		"move_right":
			out.append(_key(KEY_D))
		"move_forward":
			out.append(_key(KEY_W))
		"move_back":
			out.append(_key(KEY_S))
		"crouch":
			out.append(_key(KEY_CTRL))
		"sprint":
			out.append(_key(KEY_SHIFT))
		"lean_left":
			out.append(_key(KEY_Q))
		"lean_right":
			out.append(_key(KEY_E))
		"zoom":
			out.append(_mouse(MOUSE_BUTTON_RIGHT))
		"capture":
			out.append(_mouse(MOUSE_BUTTON_LEFT))
		"interact":
			out.append(_key(KEY_F))
		"pause":
			out.append(_key(KEY_ESCAPE))
		"album":
			out.append(_key(KEY_TAB))
	return out


func _save_bindings(cfg: ConfigFile) -> void:
	for action in GAMEPLAY_ACTIONS:
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			continue
		var strs := PackedStringArray()
		for e in events:
			strs.append(var_to_str(e))
		cfg.set_value(BINDINGS_SECTION, action, strs)


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	return ev


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	return ev


# --- Getters / setters ---

func get_mouse_sensitivity() -> float:
	return mouse_sensitivity


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = value


func get_invert_y() -> bool:
	return invert_y


func set_invert_y(value: bool) -> void:
	invert_y = value


func get_master_volume() -> float:
	return master_volume


func set_master_volume(value: float) -> void:
	master_volume = value


func get_sfx_volume() -> float:
	return sfx_volume


func set_sfx_volume(value: float) -> void:
	sfx_volume = value


func get_music_volume() -> float:
	return music_volume


func set_music_volume(value: float) -> void:
	music_volume = value
