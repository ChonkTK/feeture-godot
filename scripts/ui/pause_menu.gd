class_name PauseMenu
extends CanvasLayer
## M3c pause menu (built entirely in code): owns the pause state (tree.paused
## + mouse mode). Resume / Settings / Quit buttons; Esc toggles (routed by the
## HUD, which is the single input owner for pause/album). Settings opens the
## SettingsMenu child. process_mode ALWAYS so it works while paused.

var _paused := false
var _overlay: Control
var _buttons_box: VBoxContainer
var _settings_menu: SettingsMenu


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_settings_menu = SettingsMenu.new()
	_settings_menu.closed.connect(_on_settings_closed)
	_overlay.add_child(_settings_menu)


func is_open() -> bool:
	return _paused


func is_settings_open() -> bool:
	return _settings_menu.is_visible_in_tree()


func toggle() -> void:
	if _paused:
		close()
	else:
		open()


func open() -> void:
	_paused = true
	get_tree().paused = true
	_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_focus_first()


func close() -> void:
	if not _paused:
		return
	_paused = false
	_settings_menu.close()
	_overlay.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Esc while settings is open returns to the pause menu (called by the HUD).
func close_settings() -> void:
	_settings_menu.close()
	_buttons_box.visible = true
	_focus_first()


func _on_resume() -> void:
	close()


func _on_settings() -> void:
	_buttons_box.visible = false
	_settings_menu.open()


func _on_settings_closed() -> void:
	_buttons_box.visible = true
	_focus_first()


func _on_quit() -> void:
	get_tree().quit()


func _focus_first() -> void:
	var resume: Button = _buttons_box.get_node_or_null("ResumeButton")
	if resume != null:
		resume.grab_focus()


# --- UI construction ---------------------------------------------------------

func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "PauseOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 40)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-120, -160)
	title.size = Vector2(240, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(title)

	_buttons_box = VBoxContainer.new()
	_buttons_box.set_anchors_preset(Control.PRESET_CENTER)
	_buttons_box.position = Vector2(-80, -60)
	_buttons_box.add_theme_constant_override("separation", 12)
	_overlay.add_child(_buttons_box)

	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(160, 40)
	resume.focus_mode = Control.FOCUS_ALL
	resume.pressed.connect(_on_resume)
	_buttons_box.add_child(resume)

	var settings_btn := Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(160, 40)
	settings_btn.focus_mode = Control.FOCUS_ALL
	settings_btn.pressed.connect(_on_settings)
	_buttons_box.add_child(settings_btn)

	var quit := Button.new()
	quit.text = "Quit"
	quit.custom_minimum_size = Vector2(160, 40)
	quit.focus_mode = Control.FOCUS_ALL
	quit.pressed.connect(_on_quit)
	_buttons_box.add_child(quit)

	var hint := Label.new()
	hint.text = "Esc: resume  ·  Gamepad: A accept / B back"
	hint.add_theme_font_size_override("font_size", 14)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-200, -40)
	hint.size = Vector2(400, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(hint)
