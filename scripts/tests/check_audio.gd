extends SceneTree
## M3b audio test. The AudioManager autoload is registered in project.godot,
## so it exists under /root when this --script runs (autoloads ARE loaded,
## but the script itself cannot reference autoload identifiers at compile
## time — look them up with root.get_node()). Asserts:
##  - all four clips generated: data non-empty, expected duration, loops set
##    on crowd/tension;
##  - the public API (play_footstep, play_shutter, set_crowd_volume,
##    set_tension) runs without errors and updates state;
##  - volume math follows Settings: sfx = master*sfx,
##    ambience = master*sfx*crowd_volume, music = master*music*(0.25+0.75*t);
##  - per-level crowd_volume values are set on the LevelDefinitions.

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

	# --- (a) clips generated, non-empty, correct duration, loops set ---
	var expected_duration := {"footstep": 0.09, "shutter": 0.07, "crowd": 2.0, "tension": 4.0}
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
		if label == "crowd" or label == "tension":
			if clip.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				_fail("%s clip not looping (mode %d)" % [label, clip.loop_mode])
			if clip.loop_end <= 0:
				_fail("%s clip loop_end not set" % label)

	# --- (b) API calls without errors ---
	am.play_footstep(4.0)
	if not am._sfx.playing:
		_fail("play_footstep did not start playback")
	am.play_shutter()
	if not am._sfx.playing:
		_fail("play_shutter did not start playback")
	am.set_crowd_volume(0.7)
	if absf(am.crowd_volume - 0.7) > 0.001:
		_fail("set_crowd_volume did not stick (got %f)" % am.crowd_volume)
	am.set_tension(0.5)
	if absf(am.tension - 0.5) > 0.001:
		_fail("set_tension did not stick (got %f)" % am.tension)

	# --- (c) volume math (Settings pinned to 1.0) ---
	am._update_volumes()
	if absf(am._sfx.volume_db - linear_to_db(1.0)) > 0.5:
		_fail("sfx volume wrong (got %f)" % am._sfx.volume_db)
	if absf(am._ambience.volume_db - linear_to_db(0.7)) > 0.5:
		_fail("ambience volume wrong (got %f, expected %f)" % [am._ambience.volume_db, linear_to_db(0.7)])
	if absf(am._music.volume_db - linear_to_db(0.25 + 0.75 * 0.5)) > 0.5:
		_fail("music volume wrong (got %f, expected %f)" % [am._music.volume_db, linear_to_db(0.25 + 0.75 * 0.5)])

	# --- (d) per-level crowd volumes ---
	var expected := {"Beach": 0.7, "Subway": 0.8, "Restaurant": 0.6, "Park": 0.5}
	for ldef in [BeachLevel.create(), SubwayLevel.create(), RestaurantLevel.create(), ParkLevel.create()]:
		if absf(ldef.crowd_volume - expected[ldef.name]) > 0.001:
			_fail("%s crowd_volume %f != %f" % [ldef.name, ldef.crowd_volume, expected[ldef.name]])

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
