class_name HUD
extends CanvasLayer
## M2c HUD: built entirely in code (no .tscn). Top-left level name + photo
## count + total score; top-right TARGETS checklist ("[x] Name / [ ] Name");
## bottom global creep bar (green -> red); center messages ("Captured: ...",
## "HIDDEN", "CAUGHT — restarting...", "LEVEL COMPLETE"); Esc pause overlay
## (resume/quit). Wired to GameManager signals (photo_captured, state_changed,
## target_photographed) and the player's is_hidden state.
##
## Autoloads are looked up at runtime with get_node() because this script is
## compiled during autoload init (GameManager builds it in _ready), where
## autoload identifiers are not resolvable. The state enum is re-declared here
## (values match GameManager.State).

enum State { BOOT, PLAYING, CAUGHT, COMPLETE }

const MESSAGE_DURATION := 2.0

var _level_label: Label
var _score_label: Label
var _targets_label: Label
var _creep_fill: ColorRect
var _message_label: Label
var _hidden_label: Label
var _pause_overlay: Control
var _paused := false
var _message_timer := 0.0
var _persistent_message := ""


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
	# Transient message timer.
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0 and _persistent_message.is_empty():
			_message_label.text = ""
	# Keep the photo count / total score fresh (album is the source of truth).
	_refresh_score()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	_pause_overlay.visible = _paused
	if _paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_photo_captured(npc_name: String, score: int, rank: String) -> void:
	_show_message("Captured: %s  %s  %d pts" % [npc_name, rank, score], MESSAGE_DURATION)
	_refresh_score()


func _on_target_photographed(_npc_name: String) -> void:
	_refresh_targets()


func _on_state_changed(new_state: int) -> void:
	match new_state:
		State.PLAYING:
			_persistent_message = ""
			_message_label.text = ""
			_message_timer = 0.0
			_refresh_level()
			_refresh_targets()
		State.CAUGHT:
			_show_message("CAUGHT — restarting...", 0.0)
		State.COMPLETE:
			_show_message("LEVEL COMPLETE", 0.0)


func _show_message(text: String, duration: float) -> void:
	_message_label.text = text
	_message_timer = duration
	_persistent_message = "" if duration > 0.0 else text


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
		lines.append(("[x] " if done else "[ ] ") + t.npc_name)
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

	# Top-right: TARGETS checklist.
	_targets_label = Label.new()
	_targets_label.add_theme_font_size_override("font_size", 18)
	_targets_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_targets_label.position = Vector2(-240, 12)
	_targets_label.size = Vector2(220, 200)
	_targets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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

	# Bottom-center: creep bar (background + green->red fill).
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

	# Center: message label.
	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 32)
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.position = Vector2(-300, -30)
	_message_label.size = Vector2(600, 60)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(_message_label)

	_build_pause_overlay(root_control)


func _build_pause_overlay(parent: Control) -> void:
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	parent.add_child(_pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(dim)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 40)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-120, -140)
	title.size = Vector2(240, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_overlay.add_child(title)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-80, -60)
	box.add_theme_constant_override("separation", 12)
	_pause_overlay.add_child(box)
	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(160, 40)
	resume.pressed.connect(_on_resume_pressed)
	box.add_child(resume)
	var quit := Button.new()
	quit.text = "Quit"
	quit.custom_minimum_size = Vector2(160, 40)
	quit.pressed.connect(_on_quit_pressed)
	box.add_child(quit)


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_quit_pressed() -> void:
	get_tree().quit()
