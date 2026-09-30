class_name HUD
extends CanvasLayer
## M2c HUD: built entirely in code (no .tscn). Top-left level name + photo
## count + total score; top-right TARGETS checklist (styled, [x] green /
## [ ] grey); bottom global creep bar (green -> red) with a CREEP label;
## center message queue (up to 3 stacked messages); bottom-left controller
## hint. M3c: the pause overlay moved to PauseMenu and the album browser to
## AlbumUI — the HUD is the single input owner for the pause/album actions
## (routes them, so there is no double-pause). Wired to GameManager signals
## (photo_captured, state_changed, target_photographed) and the player's
## is_hidden state.
##
## Autoloads are looked up at runtime with get_node() because this script is
## compiled during autoload init (GameManager builds it in _ready), where
## autoload identifiers are not resolvable. The state enum is re-declared
## here (values match GameManager.State).

enum State { BOOT, PLAYING, CAUGHT, COMPLETE }

const MESSAGE_DURATION := 2.0
const MAX_MESSAGES := 3

var _level_label: Label
var _score_label: Label
var _targets_label: RichTextLabel
var _creep_fill: ColorRect
var _message_label: Label
var _hidden_label: Label
var _hint_label: Label
var _pause_menu: PauseMenu
var _album_ui: AlbumUI
var _messages: Array[Dictionary] = []  # {text, time}; time -1 = persistent


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep HUD alive while paused
	_build_ui()
	var gm := get_node("/root/GameManager")
	gm.photo_captured.connect(_on_photo_captured)
	gm.state_changed.connect(_on_state_changed)
	gm.target_photographed.connect(_on_target_photographed)
	_refresh_level()
	_refresh_score()
	_refresh_targets()


func _process(delta: float) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	# Creep bar: global creep 0..100, green -> red.
	var t := clampf(gm.global_creep / 100.0, 0.0, 1.0)
	_creep_fill.color = Color(0.2 + 0.7 * t, 0.9 - 0.7 * t, 0.3)
	_creep_fill.size.x = 300.0 * t
	# Hidden indicator (player state).
	_hidden_label.visible = gm.player != null and gm.player.is_hidden
	# Message queue expiry.
	_tick_messages(delta)
	# Keep the photo count / total score fresh (album is the source of truth).
	_refresh_score()


## Single input owner for pause/album: Esc toggles the pause menu (or closes
## the album / settings first), Tab toggles the album (ignored while paused).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _album_ui.is_open():
			_album_ui.close()
		elif _pause_menu.is_open() and _pause_menu.is_settings_open():
			_pause_menu.close_settings()
		else:
			_pause_menu.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("album"):
		if not _pause_menu.is_open():
			_album_ui.toggle()
		get_viewport().set_input_as_handled()


func _on_photo_captured(npc_name: String, score: int, rank: String) -> void:
	_show_message("Captured: %s  %s  %d pts" % [npc_name, rank, score], MESSAGE_DURATION)
	_refresh_score()


func _on_target_photographed(_npc_name: String) -> void:
	_refresh_targets()


func _on_state_changed(new_state: int) -> void:
	match new_state:
		State.PLAYING:
			_messages.clear()
			_render_messages()
			_refresh_level()
			_refresh_targets()
		State.CAUGHT:
			_show_message("CAUGHT — restarting...", 0.0)
		State.COMPLETE:
			_show_message("LEVEL COMPLETE", 0.0)


func _show_message(text: String, duration: float) -> void:
	_messages.append({"text": text, "time": duration if duration > 0.0 else -1.0})
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_render_messages()


func _render_messages() -> void:
	var lines: Array[String] = []
	for m in _messages:
		lines.append(m["text"])
	_message_label.text = "\n".join(lines)


func _tick_messages(delta: float) -> void:
	var changed := false
	for i in range(_messages.size() - 1, -1, -1):
		var m: Dictionary = _messages[i]
		if m["time"] > 0.0:
			m["time"] = m["time"] - delta
			if m["time"] <= 0.0:
				_messages.remove_at(i)
				changed = true
	if changed:
		_render_messages()


func _refresh_level() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or gm.current_level == null:
		return
	_level_label.text = gm.current_level.name


func _refresh_score() -> void:
	var album := get_node_or_null("/root/PhotoAlbum")
	if album == null:
		return
	_score_label.text = "Photos: %d   Score: %d" % [album.count, album.total_score]


func _refresh_targets() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var lines: Array[String] = []
	for t in gm.targets:
		var done: bool = t.npc_name in gm.targets_photographed
		if done:
			lines.append("[color=#7CFC00][x] %s[/color]" % t.npc_name)
		else:
			lines.append("[color=#E0E0E0][ ] %s[/color]" % t.npc_name)
	_targets_label.text = "TARGETS\n" + "\n".join(lines)


# --- UI construction (all in code) ------------------------------------------

func _build_ui() -> void:
	var root_control := Control.new()
	root_control.name = "HUD"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# Top-left: level name + photo count + total score.
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(16, 12)
	root_control.add_child(top_left)
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 26)
	top_left.add_child(_level_label)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 18)
	top_left.add_child(_score_label)

	# Top-right: TARGETS checklist (RichTextLabel for per-line color).
	_targets_label = RichTextLabel.new()
	_targets_label.bbcode_enabled = true
	_targets_label.fit_content = true
	_targets_label.scroll_active = false
	_targets_label.add_theme_font_size_override("normal_font_size", 18)
	_targets_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_targets_label.position = Vector2(-240, 12)
	_targets_label.size = Vector2(220, 200)
	root_control.add_child(_targets_label)

	# Top-center: HIDDEN indicator.
	_hidden_label = Label.new()
	_hidden_label.text = "HIDDEN"
	_hidden_label.add_theme_font_size_override("font_size", 20)
	_hidden_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hidden_label.position = Vector2(-50, 12)
	_hidden_label.size = Vector2(100, 30)
	_hidden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hidden_label.visible = false
	root_control.add_child(_hidden_label)

	# Bottom-center: creep bar (label + background + green->red fill).
	var creep_label := Label.new()
	creep_label.text = "CREEP"
	creep_label.add_theme_font_size_override("font_size", 12)
	creep_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	creep_label.position = Vector2(-150, -58)
	creep_label.size = Vector2(300, 16)
	creep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(creep_label)
	var bar := ColorRect.new()
	bar.color = Color(0.1, 0.1, 0.1, 0.8)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-150, -40)
	bar.size = Vector2(300, 16)
	root_control.add_child(bar)
	_creep_fill = ColorRect.new()
	_creep_fill.color = Color(0.2, 0.9, 0.3)
	_creep_fill.position = Vector2.ZERO
	_creep_fill.size = Vector2(300, 16)
	bar.add_child(_creep_fill)

	# Center: message label (stacked queue).
	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 30)
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.position = Vector2(-300, -50)
	_message_label.size = Vector2(600, 100)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(_message_label)

	# Bottom-left: controller hint.
	_hint_label = Label.new()
	_hint_label.text = "WASD move · Shift sprint · Ctrl crouch · LMB capture · Tab album · Esc pause · Gamepad supported"
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint_label.position = Vector2(16, -28)
	_hint_label.size = Vector2(700, 20)
	root_control.add_child(_hint_label)

	# M3c: pause menu + album browser (delegated; HUD routes their input).
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_album_ui = AlbumUI.new()
	add_child(_album_ui)
