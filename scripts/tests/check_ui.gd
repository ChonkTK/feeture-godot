extends SceneTree
## M3c UI test: builds the settings menu (sliders + 13 remap buttons),
## simulates a remap (rebind move_forward to a new key via InputMap, assert
## the new event is present and persists after save/load), resets defaults,
## opens the album with a fake record and asserts the grid has an item,
## toggles pause (tree.paused), and checks the ui_* actions have gamepad
## bindings. Deferred to _process so autoloads are registered.

var _checked := false
var _failures: Array[String] = []


func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true
	_run()
	return false


func _run() -> void:
	# --- (a) settings menu builds + slider/toggle wiring ---
	var sm: Control = _new_ui("res://scripts/ui/settings_menu.gd")
	if sm == null:
		_finish()
		return
	sm.open()
	if sm._remap_buttons.size() != 13:
		_fail("settings remap buttons %d != 13" % sm._remap_buttons.size())
	var settings := root.get_node("Settings")
	sm._sens_slider.value = 0.005
	if absf(settings.mouse_sensitivity - 0.005) > 0.0001:
		_fail("sensitivity slider did not update Settings (got %f)" % settings.mouse_sensitivity)
	sm._invert_toggle.button_pressed = true
	if not settings.invert_y:
		_fail("invert toggle did not update Settings")
	sm._invert_toggle.button_pressed = false
	sm.close()

	# --- (b) remap + persistence + reset ---
	var new_key := InputEventKey.new()
	new_key.physical_keycode = KEY_K
	InputMap.action_erase_events("move_forward")
	InputMap.action_add_event("move_forward", new_key)
	var events := InputMap.action_get_events("move_forward")
	if events.size() != 1 or (events[0] as InputEventKey).physical_keycode != KEY_K:
		_fail("move_forward rebind did not stick")
	settings.save_settings()
	InputMap.action_erase_events("move_forward")
	settings.load_input_bindings()
	events = InputMap.action_get_events("move_forward")
	if events.size() != 1 or (events[0] as InputEventKey).physical_keycode != KEY_K:
		_fail("move_forward binding did not persist after save/load")
	settings.reset_input_bindings()
	events = InputMap.action_get_events("move_forward")
	if events.size() != 1 or (events[0] as InputEventKey).physical_keycode != KEY_W:
		_fail("reset_input_bindings did not restore W for move_forward")

	# --- (c) album with a fake record ---
	var album := root.get_node("PhotoAlbum")
	album.clear()
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.5, 0.7))
	album.add_record("Test NPC", "Beach", 85, "A", img)
	var au: CanvasLayer = _new_ui("res://scripts/ui/album_ui.gd")
	if au != null:
		au.open()
		if not au.is_open():
			_fail("album did not open")
		if au._grid.get_child_count() != 1:
			_fail("album grid items %d != 1" % au._grid.get_child_count())
		au.close()
		if au.is_open():
			_fail("album did not close")
		if paused:
			_fail("tree.paused not cleared after album close")

	# --- (d) pause toggle ---
	var pm: CanvasLayer = _new_ui("res://scripts/ui/pause_menu.gd")
	if pm != null:
		pm.toggle()
		if not pm.is_open():
			_fail("pause did not open")
		if not paused:
			_fail("tree.paused not set by pause menu")
		pm.toggle()
		if pm.is_open():
			_fail("pause did not close")
		if paused:
			_fail("tree.paused not cleared by pause menu")

	# --- (e) ui_* actions have gamepad bindings ---
	for a in ["ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]:
		var has_joy := false
		for e in InputMap.action_get_events(a):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				has_joy = true
		if not has_joy:
			_fail("%s has no gamepad binding" % a)

	# Cleanup: restore default sensitivity so user://settings.cfg stays clean.
	settings.set_mouse_sensitivity(0.003)
	settings.set_invert_y(false)
	settings.save_settings()

	_finish()


func _new_ui(path: String) -> Node:
	var script: GDScript = load(path)
	if script == null:
		_fail("%s failed to load" % path)
		return null
	var node: Node = script.new()
	root.add_child(node)
	return node


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("UI CHECK OK")
		quit(0)
	else:
		print("UI CHECK FAIL: " + "; ".join(_failures))
		quit(1)
