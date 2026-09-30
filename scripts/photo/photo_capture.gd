class_name PhotoCapture
extends Node3D
## Photo capture component (M2b): child of the player. On the capture action
## (LMB) it raycasts from the camera center to the "feet" group, finds the NPC
## ancestor, scores the photo (distance/zoom/angle/face), records it in the
## PhotoAlbum autoload, saves a PNG, emits photo_captured, and spikes creep
## (shutter noise + direct bump on the target). White flash feedback via a
## full-screen ColorRect.
##
## Autoloads (PhotoAlbum, NoiseSystem, GameManager) are looked up at runtime
## with get_node() so this script stays compilable from --script tests, where
## autoload identifiers are not resolvable at compile time.

signal photo_captured(npc_name: String, score: int, rank: String)

const CAPTURE_RANGE := 60.0
const COOLDOWN := 1.0

# Scoring (M2b): base 50 + distance (closer better, <=30) + zoom (<=20) +
# angle (low/creepy downward aim, <=15) + face visible (+15). Clamped 0..100.
const BASE_SCORE := 50
const MAX_DISTANCE_BONUS := 30.0
const DISTANCE_FULL := 10.0  # distance at which the distance bonus reaches 0
const MAX_ZOOM_BONUS := 20.0
const NORMAL_FOV := 70.0
const ZOOM_FOV := 10.0
const MAX_ANGLE_BONUS := 15.0
const ANGLE_FULL_DEG := 60.0  # downward pitch at which the angle bonus maxes
const FACE_VISIBLE_BONUS := 15

const PHOTO_NOISE_RADIUS := 8.0
const PHOTO_NOISE_LOUDNESS := 4.0
const CREEP_BUMP := 5.0

const FLASH_DECAY := 3.0

var cooldown_remaining := 0.0
var last_result: Dictionary = {}

var _player: Node3D
var _camera: Camera3D
var _flash: ColorRect
var _flash_alpha := 0.0


func _ready() -> void:
	_player = get_parent() as Node3D
	_camera = _player.get_node("Camera") as Camera3D
	_build_flash()


func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * FLASH_DECAY)
		_flash.color = Color(1.0, 1.0, 1.0, _flash_alpha)


## Attempts a photo capture. Returns true when a photo was taken (cooldown
## ready and the camera-center ray hits an NPC's feet). Called by the player
## on the capture action and directly by tests.
func try_capture() -> bool:
	if cooldown_remaining > 0.0:
		return false
	var result := _raycast_feet()
	if result.is_empty():
		return false
	var node := result.collider as Node
	if node == null:
		return false
	var foot := _find_in_group(node, "feet")
	if foot == null:
		return false
	var npc := _find_npc(node)
	if npc == null:
		return false

	var score := _compute_score(npc, foot.global_position)
	var rank := _rank_for(score)
	var img := _capture_viewport_image()
	var path := "user://photos/Feeture_%s.png" % _timestamp_string()
	var album := get_node("/root/PhotoAlbum")
	album.add_record(npc.npc_name, _level_name(), score, rank, img)
	album.save_png(img, path)

	last_result = {
		"npc_name": npc.npc_name,
		"score": score,
		"rank": rank,
		"path": path,
	}
	cooldown_remaining = COOLDOWN
	_flash_alpha = 0.9

	# Creep spike: shutter noise reaches nearby NPCs + direct bump on the target.
	var noise := get_node("/root/NoiseSystem")
	noise.emit_noise(_player.global_position, PHOTO_NOISE_RADIUS, PHOTO_NOISE_LOUDNESS)
	npc.add_creep(CREEP_BUMP)

	photo_captured.emit(npc.npc_name, score, rank)
	return true


## Camera-center raycast to the "feet" group (same exclusions as the player's
## aim ray: skip the player's own body and all NPC bodies so the ray can reach
## the feet Area3D triggers instead of the NPC capsule).
func _raycast_feet() -> Dictionary:
	var space := _camera.get_world_3d().direct_space_state
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * CAPTURE_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	# Skip every player body (self + any test/other player) and all NPC bodies
	# so the ray can reach the feet Area3D triggers instead of a capsule.
	var exclude: Array[RID] = []
	for p in get_tree().get_nodes_in_group("player"):
		if p is PhysicsBody3D:
			exclude.append(p.get_rid())
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is PhysicsBody3D:
			exclude.append(npc.get_rid())
	query.exclude = exclude
	return space.intersect_ray(query)


## Walks up the tree from a hit collider looking for a node in `group`.
func _find_in_group(node: Node, group: String) -> Node3D:
	var cur := node
	while cur != null:
		if cur.is_in_group(group):
			return cur as Node3D
		cur = cur.get_parent()
	return null


## Walks up the tree from a hit collider looking for the NPC ancestor.
func _find_npc(node: Node) -> Node3D:
	var cur := node
	while cur != null:
		if cur is NPC:
			return cur as Node3D
		cur = cur.get_parent()
	return null


## M2b scoring: base 50 + distance + zoom + angle + face, clamped to 0..100.
func _compute_score(npc: Node3D, feet_pos: Vector3) -> int:
	var dist := _camera.global_position.distance_to(feet_pos)
	var dist_bonus := MAX_DISTANCE_BONUS * clampf(1.0 - dist / DISTANCE_FULL, 0.0, 1.0)
	var zoom_bonus := MAX_ZOOM_BONUS * clampf((NORMAL_FOV - _camera.fov) / (NORMAL_FOV - ZOOM_FOV), 0.0, 1.0)
	var dir := (feet_pos - _camera.global_position).normalized()
	var angle_deg := rad_to_deg(asin(clampf(-dir.y, -1.0, 1.0)))
	var angle_bonus := MAX_ANGLE_BONUS * clampf(angle_deg / ANGLE_FULL_DEG, 0.0, 1.0)
	var face_bonus := FACE_VISIBLE_BONUS if _face_visible(npc) else 0
	var total := BASE_SCORE + dist_bonus + zoom_bonus + angle_bonus + face_bonus
	return clampi(roundi(total), 0, 100)


## Face visible: ray from the camera to the NPC's head with no occlusion
## (NPC bodies and the player's own body are excluded — only the environment
## can block the face).
func _face_visible(npc: Node3D) -> bool:
	var head_pos := npc.global_position + Vector3(0.0, 1.62, 0.0)
	var space := _camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(_camera.global_position, head_pos)
	var exclude: Array[RID] = []
	for p in get_tree().get_nodes_in_group("player"):
		if p is PhysicsBody3D:
			exclude.append(p.get_rid())
	for other in get_tree().get_nodes_in_group("npcs"):
		if other is PhysicsBody3D:
			exclude.append(other.get_rid())
	query.exclude = exclude
	return space.intersect_ray(query).is_empty()


func _rank_for(score: int) -> String:
	if score >= 90:
		return "S"
	if score >= 75:
		return "A"
	if score >= 60:
		return "B"
	return "C"


## Viewport image for the album. Headless has no readable viewport texture, so
## it gets a solid placeholder (the PNG still round-trips through save_png).
func _capture_viewport_image() -> Image:
	if DisplayServer.get_name() == "headless":
		return _placeholder_image()
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return _placeholder_image()
	return img


func _placeholder_image() -> Image:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(Color(0.1, 0.1, 0.12))
	return img


func _timestamp_string() -> String:
	return Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")


func _level_name() -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.current_level != null:
		return gm.current_level.name
	var parent := _player.get_parent()
	if parent != null:
		return parent.name
	return "?"


## Brief full-screen white flash (HUD feedback for the shutter).
func _build_flash() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FlashLayer"
	layer.layer = 100
	var rect := ColorRect.new()
	rect.name = "Flash"
	rect.color = Color(1.0, 1.0, 1.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)
	_flash = rect
