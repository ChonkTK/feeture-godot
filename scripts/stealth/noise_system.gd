extends Node
## NoiseSystem autoload (M2a): global noise propagation. emit_noise() makes
## every NPC within radius suspicious of the position; the creep added scales
## with distance falloff (loudness at the source, ~0 at the edge of the radius).

func emit_noise(pos: Vector3, radius: float, loudness: float) -> void:
	if radius <= 0.0 or loudness <= 0.0:
		return
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc):
			continue
		var dist := pos.distance_to(npc.global_position)
		if dist > radius:
			continue
		var falloff := 1.0 - dist / radius
		npc.hear_noise(pos, loudness * falloff)
