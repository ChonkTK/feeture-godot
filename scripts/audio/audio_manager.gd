extends Node
## AudioManager autoload (M3b): fully procedural one-shot SFX — no audio files.
## Generates AudioStreamWAV clips in code (16-bit PCM @ 22050 Hz):
##   - footstep: low-passed noise burst + low thump (~0.09s)
##   - shutter:  sharp click + 900 Hz square burst (~0.07s)
## Plays them through a single AudioStreamPlayer node (SFX). The looping
## crowd ambience and tension music were removed (M3d) — no Ambience/Music
## players, no loop clips.
## Volume follows the Settings autoload every frame: sfx = master * sfx.
## API: play_footstep(speed), play_shutter().
##
## Autoloads (Settings, GameManager) are looked up at runtime with
## get_node_or_null() so this script stays compilable from --script tests,
## where autoload identifiers are not resolvable at compile time.
##
## NOTE: Godot 4.7 GDScript has no try/except (verified: `try:` is a parse
## error), so generation is guarded by a validity check + null propagation:
## a failed clip is dropped with a warning and every consumer null-checks
## before use — a generation failure can never crash the game.

const MIX_RATE := 22050

var _sfx: AudioStreamPlayer
var _sfx_gain := 0.0  # per-play gain offset (footstep speed / shutter)

var _footstep_clip: AudioStreamWAV
var _shutter_clip: AudioStreamWAV


func _ready() -> void:
	_build_players()
	_generate_clips()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_signal("photo_captured"):
		gm.photo_captured.connect(_on_photo_captured)


func _process(_delta: float) -> void:
	_update_volumes()


# --- Public API --------------------------------------------------------------

## Plays a footstep; `speed` scales pitch (faster = higher) and gain
## (sprint louder, crouch-walk quieter).
func play_footstep(speed: float) -> void:
	if _footstep_clip == null:
		return
	_sfx.stream = _footstep_clip
	var f := clampf(speed / 6.5, 0.0, 1.0)
	_sfx.pitch_scale = lerpf(0.85, 1.15, f)
	_sfx_gain = lerpf(-10.0, -2.0, f)
	_sfx.play()


## Plays the camera shutter click.
func play_shutter() -> void:
	if _shutter_clip == null:
		return
	_sfx.stream = _shutter_clip
	_sfx.pitch_scale = 1.0
	_sfx_gain = 0.0
	_sfx.play()


## Returns a generated clip by name ("footstep", "shutter") or null. Used by
## tests. "crowd"/"tension" return null — the looping ambience/music clips
## were removed.
func get_clip(clip_name: String) -> AudioStreamWAV:
	match clip_name:
		"footstep":
			return _footstep_clip
		"shutter":
			return _shutter_clip
	return null


# --- Volume ------------------------------------------------------------------

func _update_volumes() -> void:
	var settings := get_node_or_null("/root/Settings")
	var master := 1.0
	var sfx := 1.0
	if settings != null:
		master = settings.master_volume
		sfx = settings.sfx_volume
	_sfx.volume_db = linear_to_db(maxf(master * sfx, 0.0001)) + _sfx_gain


# --- Players / clips ----------------------------------------------------------

func _build_players() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.name = "SFX"
	add_child(_sfx)


func _generate_clips() -> void:
	_footstep_clip = _safe_generate(_make_footstep, "footstep")
	_shutter_clip = _safe_generate(_make_shutter, "shutter")


## Guard: Godot 4.7 has no try/except, so a failed generation returns null
## and is dropped with a warning — consumers all null-check before use.
func _safe_generate(maker: Callable, label: String) -> AudioStreamWAV:
	var clip: AudioStreamWAV = maker.call()
	if clip == null or clip.data.is_empty() or clip.get_length() <= 0.0:
		push_warning("AudioManager: %s clip generation failed — audio disabled" % label)
		return null
	return clip


func _on_photo_captured(_npc_name: String, _score: int, _rank: String) -> void:
	play_shutter()


# --- Clip synthesis ----------------------------------------------------------

## Footstep: low-passed noise burst + low thump, exp decay, ~0.09s.
func _make_footstep() -> AudioStreamWAV:
	var n := int(0.09 * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		lp = lp + 0.18 * (noise - lp)
		var thump := sin(TAU * 75.0 * t) * exp(-t / 0.018)
		var env := exp(-t / 0.028)
		data.encode_s16(i * 2, _to_s16((lp * 0.6 + thump * 0.7) * env))
	return _make_wav(data, n)


## Shutter: sharp click + 900 Hz square burst, fast decay, ~0.07s.
func _make_shutter() -> AudioStreamWAV:
	var n := int(0.07 * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var click := rng.randf_range(-1.0, 1.0) * exp(-t / 0.0025)
		var sq := 1.0 if fmod(t * 900.0, 1.0) < 0.5 else -1.0
		data.encode_s16(i * 2, _to_s16(click * 0.7 + sq * 0.5 * exp(-t / 0.02)))
	return _make_wav(data, n)


func _make_wav(data: PackedByteArray, sample_count: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


func _to_s16(v: float) -> int:
	return clampi(int(round(clampf(v, -1.0, 1.0) * 32767.0)), -32768, 32767)
