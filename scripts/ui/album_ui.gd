class_name AlbumUI
extends CanvasLayer
## M3c album browser (built entirely in code): grid of photo thumbnails from
## the PhotoAlbum autoload; click a thumbnail to view details (npc_name,
## score, rank, level, timestamp). Opened by the album action (Tab, routed by
## the HUD); closes on Esc (HUD) or Tab (this node's _input). Pauses the game
## while open. process_mode ALWAYS so it works while paused.

const COLS := 4

var _overlay: Control
var _grid: GridContainer
var _details_panel: Control
var _details_texture: TextureRect
var _details_name: Label
var _details_score: Label
var _details_level: Label
var _details_time: Label
var _open := false


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	_open = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_grid()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_hide_details()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Tab closes the album even when a thumbnail button has focus (GUI consumes
## Tab for focus navigation before _unhandled_input would see it).
func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_TAB:
			close()
			get_viewport().set_input_as_handled()


func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var album := get_node_or_null("/root/PhotoAlbum")
	if album == null:
		return
	for i in album.records.size():
		_grid.add_child(_make_thumb(album.records[i], i))


func _make_thumb(rec: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 150)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(_on_thumb_pressed.bind(index))
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(130, 110)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img: Image = rec.get("texture")
	if img != null:
		tex_rect.texture = ImageTexture.create_from_image(img)
	vbox.add_child(tex_rect)
	var name_label := Label.new()
	name_label.text = str(rec.get("npc_name", "?"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	return btn


func _on_thumb_pressed(index: int) -> void:
	var album := get_node_or_null("/root/PhotoAlbum")
	if album == null or index >= album.records.size():
		return
	_show_details(album.records[index])


func _show_details(rec: Dictionary) -> void:
	_details_panel.visible = true
	var img: Image = rec.get("texture")
	if img != null:
		_details_texture.texture = ImageTexture.create_from_image(img)
	_details_name.text = "Name: %s" % rec.get("npc_name", "?")
	_details_score.text = "Score: %d   Rank: %s" % [rec.get("score", 0), rec.get("rank", "?")]
	_details_level.text = "Level: %s" % rec.get("level", "?")
	_details_time.text = "Taken: %s" % rec.get("timestamp", "?")


func _hide_details() -> void:
	_details_panel.visible = false


func _on_details_close() -> void:
	_hide_details()


# --- UI construction ---------------------------------------------------------

func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "AlbumOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	var title := Label.new()
	title.text = "PHOTO ALBUM"
	title.add_theme_font_size_override("font_size", 30)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-150, 16)
	title.size = Vector2(300, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(title)

	var hint := Label.new()
	hint.text = "Click a photo for details  ·  Esc / Tab to close"
	hint.add_theme_font_size_override("font_size", 14)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-200, -30)
	hint.size = Vector2(400, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_top = 70
	scroll.offset_right = -40
	scroll.offset_bottom = -50
	_overlay.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)

	_build_details_panel()


func _build_details_panel() -> void:
	_details_panel = Control.new()
	_details_panel.name = "DetailsPanel"
	_details_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_details_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_details_panel.visible = false
	_overlay.add_child(_details_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_panel.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -180)
	panel.size = Vector2(440, 360)
	_details_panel.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_details_texture = TextureRect.new()
	_details_texture.custom_minimum_size = Vector2(200, 150)
	_details_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_details_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_details_texture)

	_details_name = Label.new()
	_details_name.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_details_name)
	_details_score = Label.new()
	_details_score.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_details_score)
	_details_level = Label.new()
	_details_level.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_details_level)
	_details_time = Label.new()
	_details_time.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_details_time)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.focus_mode = Control.FOCUS_ALL
	close_btn.pressed.connect(_on_details_close)
	vbox.add_child(close_btn)
