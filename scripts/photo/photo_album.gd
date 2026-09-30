extends Node
## PhotoAlbum autoload (M2b): stores photo records (npc_name, level, score,
## rank, texture, timestamp), total score and count. save_png() writes photos
## to user://photos/Feeture_<timestamp>.png (creating the directory).

var records: Array[Dictionary] = []
var total_score: int = 0
var count: int = 0


## Adds a photo record and updates totals.
func add_record(npc_name: String, level: String, score: int, rank: String, texture: Image) -> void:
	records.append({
		"npc_name": npc_name,
		"level": level,
		"score": score,
		"rank": rank,
		"texture": texture,
		"timestamp": Time.get_datetime_string_from_system(),
	})
	total_score += score
	count += 1


## Writes an image to the given path (creates parent dirs). No-op on null.
func save_png(texture: Image, path: String) -> void:
	if texture == null:
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	texture.save_png(path)


## Clears all records and totals.
func clear() -> void:
	records.clear()
	total_score = 0
	count = 0
