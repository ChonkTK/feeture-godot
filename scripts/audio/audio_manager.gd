extends Node
## AudioManager autoload (M3b): fully procedural audio — no audio files.
## Generates AudioStreamWAV clips in code (16-bit PCM @ 22050 Hz):
##   - footstep: low-passed noise burst + low thump (~0.09s)
##   - shutter:  sharp click + 900 Hz square burst (~0.07s)
##   - crowd:    looped muffled noise with slow swells (~2s, seamless loop)
##   - tension:  looped low drone + 8-step minor arp (~4s, seamless loop)
## Plays them through three AudioStreamPlayer nodes (SFX, Ambience, Music).
## Volumes follow the Settings autoload every frame:
##   sfx      = master * sfx
##   ambience = master * sfx * crowd_volume
##   music    = master * music * (0.25 + 0.75 * tension)
## where tension = GameManager.global_creep / 100 (music swells with the
## creep meter). API: play_footstep(speed), play_shutter(),
## set_crowd_volume(v), set_tension(t).
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

var crowd_volume: float = 0.6
var tension: float = 0.0

var _sfx: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _music: AudioStreamPlayer
var _sfx_gain := 0.0  # per-play gain offset (footstep speed / shutter)
var _tension_override := -1.0  # -1 = follow GameManager.global_creep

var _footstep_clip: AudioStreamWAV
var _shutter_clip: AudioStreamWAV
var _crowd_clip: AudioStreamWAV
var _tension_clip: AudioStreamWAV


func _ready() -> void:
	_build_players()
	_generate_clips()
	_start_loops()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		if gm.current_level != null:
			crowd_volume = gm.current_level.crowd_volume
		if gm.has_signal("photo_captured"):
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


func set_crowd_volume(v: float) -> void:
	crowd_volume = clampf(v, 0.0, 1.0)


func set_tension(t: float) -> void:
	tension = clampf(t, 0.0, 1.0)
	_tension_override = tension


## Returns a generated clip by name ("footstep", "shutter", "crowd",
## "tension") or null. Used by tests.
func get_clip(clip_name: String) -> AudioStreamWAV:
	match clip_name:
		"footstep":
			return _footstep_clip
		"shutter":
			return _shutter_clip
		"crowd":
			return _crowd_clip
		"tension":
			return _tension_clip
	return null


# --- Volume ------------------------------------------------------------------

func _update_volumes() -> void:
	var settings := get_node_or_null("/root/Settings")
	var master := 1.0
	var sfx := 1.0
	var music := 1.0
	if settings != null:
		master = settings.master_volume
		sfx = settings.sfx_volume
		music = settings.music_volume
	var gm := get_node_or_null("/root/GameManager")
	if _tension_override < 0.0 and gm != null:
		tension = clampf(gm.global_creep / 100.0, 0.0, 1.0)
	_sfx.volume_db = linear_to_db(maxf(master * sfx, 0.0001)) + _sfx_gain
	_ambience.volume_db = linear_to_db(maxf(master * sfx * crowd_volume, 0.0001))
	_music.volume_db = linear_to_db(maxf(master * music * (0.25 + 0.75 * tension), 0.0001))


# --- Players / clips ----------------------------------------------------------

func _build_players() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.name = "SFX"
	add_child(_sfx)
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "Ambience"
	add_child(_ambience)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	add_child(_music)


func _generate_clips() -> void:
	_footstep_clip = _safe_generate(_make_footstep, "footstep")
	_shutter_clip = _safe_generate(_make_shutter, "shutter")
	_crowd_clip = _safe_generate(_make_crowd, "crowd")
	_tension_clip = _safe_generate(_make_tension, "tension")


## Guard: Godot 4.7 has no try/except, so a failed generation returns null
## and is dropped with a warning — consumers all null-check before use.
func _safe_generate(maker: Callable, label: String) -> AudioStreamWAV:
	var clip: AudioStreamWAV = maker.call()
	if clip == null or clip.data.is_empty() or clip.get_length() <= 0.0:
		push_warning("AudioManager: %s clip generation failed — audio disabled" % label)
		return null
	return clip


func _start_loops() -> void:
	if _crowd_clip != null:
		_ambience.stream = _crowd_clip
		_ambience.play()
	if _tension_clip != null:
		_music.stream = _tension_clip
		_music.play()


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
	return _make_wav(data, n, false)


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
	return _make_wav(data, n, false)


## Crowd: heavily low-passed noise with slow swells, ~2s seamless loop.
func _make_crowd() -> AudioStreamWAV:
	var n := int(2.0 * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		lp = lp + 0.05 * (noise - lp)
		# Swell LFO (0.5 Hz + 1.5 Hz — both integer-cycle in 2s).
		var lfo := 0.7 + 0.3 * sin(TAU * 0.5 * t) + 0.15 * sin(TAU * 1.5 * t)
		data.encode_s16(i * 2, _to_s16(lp * lfo))
	_seamless_loop(data, n)
	return _make_wav(data, n, true)


## Tension: low drone (A1/A2/E3/A3, all integer-cycle in 4s) + slow swell +
## 8-step minor arp, ~4s seamless loop. The creep meter swells the music via
## the volume curve in _update_volumes.
func _make_tension() -> AudioStreamWAV:
	var n := int(4.0 * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var drone := [55.0, 110.0, 165.0, 220.0]
	var drone_amp := [0.32, 0.22, 0.12, 0.06]
	var arp := [110.0, 130.81, 164.81, 196.0, 164.81, 130.81, 110.0, 130.81]
	var step := 0.5
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var s := 0.0
		for k in drone.size():
			s += drone_amp[k] * sin(TAU * drone[k] * t)
		s *= 0.6 + 0.4 * sin(TAU * 0.25 * t)  # 0.25 Hz swell (1 cycle / 4s)
		var step_idx := int(t / step) % arp.size()
		var step_t := t - float(step_idx) * step
		var note_env := exp(-step_t / 0.18) * (1.0 - step_t / step)
		s += 0.16 * sin(TAU * arp[step_idx] * step_t) * note_env
		# Fade in/out at the loop boundary for seamlessness.
		var fade := 0.05
		var env := 1.0
		if t < fade:
			env = t / fade
		elif t > 4.0 - fade:
			env = (4.0 - t) / fade
		data.encode_s16(i * 2, _to_s16(s * env))
	return _make_wav(data, n, true)


## Crossfades the tail of `data` into its head so the loop point is seamless.
func _seamless_loop(data: PackedByteArray, n: int) -> void:
	var fade := mini(int(0.1 * MIX_RATE), n / 4)
	for i in fade:
		var t := float(i) / float(fade)
		var a := data.decode_s16((n - 1 - i) * 2)
		var b := data.decode_s16(i * 2)
		data.encode_s16((n - 1 - i) * 2, int(round(a * (1.0 - t) + b * t)))


func _make_wav(data: PackedByteArray, sample_count: int, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = sample_count
	return wav


func _to_s16(v: float) -> int:
	return clampi(int(round(clampf(v, -1.0, 1.0) * 32767.0)), -32768, 32767)
