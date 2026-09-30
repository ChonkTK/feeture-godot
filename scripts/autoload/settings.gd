extends Node
## Settings autoload: mouse sensitivity, invert Y, and volume levels.
## Loads from / saves to user://settings.cfg via ConfigFile.

const SETTINGS_PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.003
var invert_y: bool = false
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0


func _ready() -> void:
	load_settings()


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
	cfg.save(SETTINGS_PATH)


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
