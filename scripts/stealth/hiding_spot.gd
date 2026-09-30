class_name HidingSpot
extends Area3D
## Hiding spot component (M2a): Area3D trigger on bushes (and a few props).
## While the player stands inside, pressing interact (F) toggles is_hidden;
## leaving the area exits hiding. Hidden players break NPC line of sight,
## decay creep faster, and make no movement noise.

var _player: Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		body.is_hidden = false  # leaving the area exits hiding


func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event.is_action_pressed("interact"):
		_player.is_hidden = not _player.is_hidden
