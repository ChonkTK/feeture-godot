class_name AmbientAnimator
extends Node3D
## M4: cheap sine animation for decorative props — bob up/down and/or sway
## rotation. A handful of these per level; no per-frame allocations.

var bob_amplitude := 0.0
var bob_speed := 2.0
var sway_amplitude := 0.0
var sway_speed := 1.5
var phase := 0.0

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	if bob_amplitude > 0.0:
		position.y = _base_y + sin(_time * bob_speed + phase) * bob_amplitude
	if sway_amplitude > 0.0:
		rotation.z = sin(_time * sway_speed + phase) * sway_amplitude
