extends SceneTree
## M3b audio test (M3d: looping ambience/music removed). The AudioManager
## autoload is registered in project.godot, so it exists under /root when this
## --script runs (autoloads ARE loaded, but the script itself cannot reference
## autoload identifiers at compile time — look them up with root.get_node()).
## Asserts:
##  - exactly the two one-shot clips exist: footstep + shutter (non-empty,
##    expected durations); crowd/tension clips and Ambience/Music players are
##    gone (get_clip returns null, no such child nodes);
##  - the public API (play_footstep, play_shutter) runs without errors and
##    starts playback;
##  - volume math follows Settings: sfx = master*sfx.

var _checked := false
var _failures: Array[String] = []


func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true
	_run()
	return false


func _run() -> void:
	var am := root.get_node_or_null("AudioManager")
	if am == null:
		_fail("AudioManager autoload missing")
		_finish()
		return
	# Pin Settings to known values (user://settings.cfg may hold others).
	var settings := root.get_node_or_null("Settings")
	if settings != null:
		settings.set_master_volume(1.0)
		settings.set_sfx_volume(1.0)
		settings.set_music_volume(1.0)

	# --- (a) one-shot clips exist, non-empty, correct duration ---
	var expected_duration := {"footstep": 0.09, "shutter": 0.07}
	for label in expected_duration:
		var clip: AudioStreamWAV = am.get_clip(label)
		if clip == null:
			_fail("%s clip missing" % label)
			continue
		if clip.data.is_empty():
			_fail("%s clip data empty" % label)
		if clip.get_length() <= 0.0:
			_fail("%s clip duration <= 0" % label)
		elif absf(clip.get_length() - expected_duration[label]) > 0.01:
			_fail("%s clip duration %f != %f" % [label, clip.get_length(), expected_duration[label]])

	# --- (b) no crowd/tension clips, no Ambience/Music players ---
	for label in ["crowd", "tension"]:
		if am.get_clip(label) != null:
			_fail("%s clip still exists (looping audio should be removed)" % label)
	for node_name in ["Ambience", "Music"]:
		if am.get_node_or_null(node_name) != null:
			_fail("%s AudioStreamPlayer still exists (looping audio should be removed)" % node_name)

	# --- (c) API calls without errors ---
	am.play_footstep(4.0)
	if not am._sfx.playing:
		_fail("play_footstep did not start playback")
	am.play_shutter()
	if not am._sfx.playing:
		_fail("play_shutter did not start playback")

	# --- (d) volume math (Settings pinned to 1.0) ---
	am._update_volumes()
	if absf(am._sfx.volume_db - linear_to_db(1.0)) > 0.5:
		_fail("sfx volume wrong (got %f)" % am._sfx.volume_db)

	_finish()


func _fail(reason: String) -> void:
	_failures.append(reason)


func _finish() -> void:
	if _failures.is_empty():
		print("AUDIO CHECK OK")
		quit(0)
	else:
		print("AUDIO CHECK FAIL: " + "; ".join(_failures))
		quit(1)
