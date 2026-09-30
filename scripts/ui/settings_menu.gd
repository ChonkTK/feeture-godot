class_name SettingsMenu
extends Control
## M3c settings menu (built entirely in code): sliders for mouse sensitivity
## and master/sfx/music volumes, an invert-Y toggle, and a remap list for the
## gameplay actions (keyboard / mouse / gamepad). Click an action to enter
## capture mode ("press a key/button..."), Escape cancels. Changes persist
## through the Settings autoload (ConfigFile user://settings.cfg, including
## InputMap bindings). process_mode ALWAYS so it works while paused.
##
## The remap list is built lazily in open() from Settings.GAMEPLAY_ACTIONS
## (runtime lookup) because this script is compiled during autoload init
## (HUD -> PauseMenu -> SettingsMenu), when autoload identifiers are not yet
## resolvable at compile time.

signal closed

const SENS_MIN := 0.0005
const SENS_MAX := 0.01
const SENS_STEP := 0.0005
const VOL_MIN := 0.0
const VOL_MAX := 1.0
const VOL_STEP := 0.01

var _capture_action := ""
var _capture_ignore_until := 0  # ms: ignore mouse events right after entering capture
var _syncing := false

var _sens_slider: HSlider
var _master_slider: HSlider
var _sfx_slider: HSlider
var _music_slider: HSlider
var _invert_toggle: CheckButton
var _sens_value: Label
var _master_value: Label
var _sfx_value: Label
var _music_value: Label
var _remap_box: VBoxContainer
var _remap_buttons: Dictionary = {}  # action -> Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func open() -> void:
	_sync_from_settings()
	_build_remap_list()
	visible = true


func close() -> void:
	if not visible:
		return
	_capture_action = ""
	visible = false
	closed.emit()


func is_capturing() -> bool:
	return not _capture_action.is_empty()


## Capture mode: any key / mouse button / gamepad button rebinds the action;
## Escape cancels. The event is consumed so it never leaks to the game.
func _input(event: InputEvent) -> void:
	if _capture_action.is_empty() or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_ESCAPE:
			_cancel_capture()
		else:
			_apply_remap(_capture_action, k)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if Time.get_ticks_msec() < _capture_ignore_until:
			return
		_apply_remap(_capture_action, event as InputEventMouseButton)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		_apply_remap(_capture_action, event as InputEventJoypadButton)
		get_viewport().set_input_as_handled()


func _apply_remap(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_capture_action = ""
	_refresh_remap_button(action)
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.save_settings()


func _cancel_capture() -> void:
	var action := _capture_action
	_capture_action = ""
	if not action.is_empty():
		_refresh_remap_button(action)


# --- UI construction ---------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-320, -280)
	panel.size = Vector2(640, 560)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sens := _make_slider_row("Mouse Sensitivity", SENS_MIN, SENS_MAX, SENS_STEP, _on_sens_changed)
	_sens_slider = sens["slider"]
	_sens_value = sens["value"]
	vbox.add_child(sens["row"])

	var master := _make_slider_row("Master Volume", VOL_MIN, VOL_MAX, VOL_STEP, _on_master_changed)
	_master_slider = master["slider"]
	_master_value = master["value"]
	vbox.add_child(master["row"])

	var sfx := _make_slider_row("SFX Volume", VOL_MIN, VOL_MAX, VOL_STEP, _on_sfx_changed)
	_sfx_slider = sfx["slider"]
	_sfx_value = sfx["value"]
	vbox.add_child(sfx["row"])

	var music := _make_slider_row("Music Volume", VOL_MIN, VOL_MAX, VOL_STEP, _on_music_changed)
	_music_slider = music["slider"]
	_music_value = music["value"]
	vbox.add_child(music["row"])

	var invert_row := HBoxContainer.new()
	var invert_label := Label.new()
	invert_label.text = "Invert Y"
	invert_label.custom_minimum_size = Vector2(180, 0)
	invert_row.add_child(invert_label)
	_invert_toggle = CheckButton.new()
	_invert_toggle.name = "InvertToggle"
	_invert_toggle.focus_mode = Control.FOCUS_ALL
	_invert_toggle.toggled.connect(_on_invert_toggled)
	invert_row.add_child(_invert_toggle)
	vbox.add_child(invert_row)

	var controls_label := Label.new()
	controls_label.text = "CONTROLS (click an action to remap)"
	controls_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(controls_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_remap_box = VBoxContainer.new()
	_remap_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_remap_box)

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons_row)
	var reset_btn := Button.new()
	reset_btn.text = "Reset Defaults"
	reset_btn.focus_mode = Control.FOCUS_ALL
	reset_btn.pressed.connect(_on_reset_defaults)
	buttons_row.add_child(reset_btn)
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(_on_back)
	buttons_row.add_child(back_btn)


func _make_slider_row(label_text: String, min_v: float, max_v: float, step_v: float, on_change: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.custom_minimum_size = Vector2(240, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(90, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(on_change)
	return {"row": row, "slider": slider, "value": value_label}


func _build_remap_list() -> void:
	for child in _remap_box.get_children():
		child.queue_free()
	_remap_buttons.clear()
	var settings := get_node_or_null("/root/Settings")
	var actions: Array[String] = []
	if settings != null:
		actions = settings.GAMEPLAY_ACTIONS
	else:
		actions = [
			"move_left", "move_right", "move_forward", "move_back",
			"crouch", "sprint", "lean_left", "lean_right",
			"zoom", "capture", "interact", "pause", "album",
		]
	for action in actions:
		_remap_box.add_child(_make_remap_row(action))


func _make_remap_row(action: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = _action_display_name(action)
	label.custom_minimum_size = Vector2(170, 0)
	row.add_child(label)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 30)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(_on_remap_pressed.bind(action, btn))
	row.add_child(btn)
	_remap_buttons[action] = btn
	_refresh_remap_button(action)
	return row


func _refresh_remap_button(action: String) -> void:
	var btn: Button = _remap_buttons.get(action)
	if btn == null:
		return
	var events := InputMap.action_get_events(action)
	var parts: Array[String] = []
	for e in events:
		parts.append(_event_label(e))
	btn.text = ", ".join(parts) if not parts.is_empty() else "(none)"


func _event_label(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		var code := k.physical_keycode if k.physical_keycode != 0 else k.keycode
		return OS.get_keycode_string(code)
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
		return "Mouse %d" % mb.button_index
	if e is InputEventJoypadButton:
		return "Pad %d" % (e as InputEventJoypadButton).button_index
	if e is InputEventJoypadMotion:
		var jm := e as InputEventJoypadMotion
		return "Pad Axis %d %s" % [jm.axis, "<" if jm.axis_value < 0.0 else ">"]
	return "?"


func _action_display_name(action: String) -> String:
	match action:
		"move_left":
			return "Move Left"
		"move_right":
			return "Move Right"
		"move_forward":
			return "Move Forward"
		"move_back":
			return "Move Back"
		"crouch":
			return "Crouch"
		"sprint":
			return "Sprint"
		"lean_left":
			return "Lean Left"
		"lean_right":
			return "Lean Right"
		"zoom":
			return "Zoom"
		"capture":
			return "Capture"
		"interact":
			return "Interact"
		"pause":
			return "Pause"
		"album":
			return "Album"
	return action


# --- Handlers ----------------------------------------------------------------

func _on_remap_pressed(action: String, btn: Button) -> void:
	_capture_action = action
	_capture_ignore_until = Time.get_ticks_msec() + 250
	btn.text = "Press a key/button... (Esc cancels)"


func _on_sens_changed(value: float) -> void:
	if _syncing:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_mouse_sensitivity(value)
		settings.save_settings()
	_sens_value.text = "%.4f" % value


func _on_master_changed(value: float) -> void:
	if _syncing:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_master_volume(value)
		settings.save_settings()
	_master_value.text = "%.2f" % value


func _on_sfx_changed(value: float) -> void:
	if _syncing:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_sfx_volume(value)
		settings.save_settings()
	_sfx_value.text = "%.2f" % value


func _on_music_changed(value: float) -> void:
	if _syncing:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_music_volume(value)
		settings.save_settings()
	_music_value.text = "%.2f" % value


func _on_invert_toggled(pressed: bool) -> void:
	if _syncing:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.set_invert_y(pressed)
		settings.save_settings()


func _on_reset_defaults() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		settings.reset_input_bindings()
	for action in _remap_buttons:
		_refresh_remap_button(action)


func _on_back() -> void:
	close()


func _sync_from_settings() -> void:
	_syncing = true
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		_sens_slider.value = settings.mouse_sensitivity
		_master_slider.value = settings.master_volume
		_sfx_slider.value = settings.sfx_volume
		_music_slider.value = settings.music_volume
		_invert_toggle.button_pressed = settings.invert_y
	_syncing = false
	_refresh_value_labels()


func _refresh_value_labels() -> void:
	_sens_value.text = "%.4f" % _sens_slider.value
	_master_value.text = "%.2f" % _master_slider.value
	_sfx_value.text = "%.2f" % _sfx_slider.value
	_music_value.text = "%.2f" % _music_slider.value
