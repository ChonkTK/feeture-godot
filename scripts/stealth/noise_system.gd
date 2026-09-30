extends Node
## NoiseSystem autoload (M2a): global noise propagation. emit_noise() makes
## every NPC within radius investigate the position; the creep added (loudness)
## scales with distance falloff. Movement noise uses loudness 0 (investigate
## only — walking isn't weird); photo capture uses loudness > 0 (weird act).

func emit_noise(pos: Vector3, radius: float, loudness: float) -> void:
	if radius <= 0.0:
		return
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc):
			continue
		var dist := pos.distance_to(npc.global_position)
		if dist > radius:
			continue
		var falloff := 1.0 - dist / radius
		npc.hear_noise(pos, loudness * falloff)
