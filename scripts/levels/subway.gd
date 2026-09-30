class_name SubwayLevel
extends RefCounted
## Subway level definition (M1b/M4): cool underground platform with ticket
## booth, snack stand, pillars, benches, trash cans, partitions, signs, lamp
## posts and planters, and a crowd of commuters. The train track stays clear
## beyond the tunnel walls at z = +/-14.

static func create() -> LevelDefinition:
	var def := LevelDefinition.new()
	def.name = "Subway"
	def.ground_size = Vector2(40.0, 40.0)
	def.ground_color = Color(0.25, 0.27, 0.3)
	def.ambient_color = Color(0.5, 0.6, 0.8)
	def.sun_color = Color(0.7, 0.8, 1.0)
	def.sun_intensity = 0.8
	def.sun_rotation = Vector3(-40.0, 20.0, 0.0)
	def.background_color = Color(0.08, 0.1, 0.16)
	def.glow_intensity = 0.1
	def.vignette_intensity = 0.1
	def.target_count = 2

	def.props = [
		# Tunnel walls + flanking platform walls.
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -14), Vector3(10.0, 3.0, 2.0), Color(0.35, 0.38, 0.45), PropData.DoorSide.FRONT, 2),
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, 14), Vector3(10.0, 3.0, 2.0), Color(0.35, 0.38, 0.45), PropData.DoorSide.BACK, 2),
		PropData.make(PropData.PropType.WALL, Vector3(-16, 0, 0), Vector3(1.0, 2.4, 20.0), Color(0.45, 0.5, 0.6)),
		PropData.make(PropData.PropType.WALL, Vector3(16, 0, 0), Vector3(1.0, 2.4, 20.0), Color(0.45, 0.5, 0.6)),
		# Ticket booth + snack stand.
		PropData.make(PropData.PropType.TICKET_BOOTH, Vector3(-10, 0, -10), Vector3(3.0, 2.4, 2.0), Color(0.4, 0.45, 0.55)),
		PropData.make(PropData.PropType.KIOSK, Vector3(10, 0, 10), Vector3(2.5, 2.2, 1.8), Color(0.55, 0.6, 0.7)),
		# Pillars down the platform.
		PropData.make(PropData.PropType.PILLAR, Vector3(-8, 0, -10), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PILLAR, Vector3(-8, 0, -2), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PILLAR, Vector3(-8, 0, 6), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PILLAR, Vector3(8, 0, -6), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PILLAR, Vector3(8, 0, 2), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PILLAR, Vector3(8, 0, 10), Vector3(0.6, 3.2, 0.6), Color(0.5, 0.55, 0.65)),
		# Benches + trash cans.
		PropData.make(PropData.PropType.BENCH, Vector3(-12, 0, 6), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.BENCH, Vector3(12, 0, -6), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.BENCH, Vector3(-12, 0, -8), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.BENCH, Vector3(12, 0, 8), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(-12, 0, 4), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.32, 0.35)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(12, 0, -4), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.32, 0.35)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(-4, 0, -12), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.32, 0.35)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(4, 0, 12), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.32, 0.35)),
		# Partitions + crates.
		PropData.make(PropData.PropType.PARTITION, Vector3(-6, 0, 4), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PARTITION, Vector3(6, 0, -4), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PARTITION, Vector3(-6, 0, -8), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PARTITION, Vector3(6, 0, 8), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.CUBE, Vector3(-4, 0, 8), Vector3(1.0, 1.0, 1.0), Color(0.6, 0.65, 0.75)),
		PropData.make(PropData.PropType.CUBE, Vector3(4, 0, -8), Vector3(1.0, 1.0, 1.0), Color(0.6, 0.65, 0.75)),
		PropData.make(PropData.PropType.CUBE, Vector3(-2, 0, 12), Vector3(0.8, 0.8, 0.8), Color(0.6, 0.65, 0.75)),
		PropData.make(PropData.PropType.CUBE, Vector3(2, 0, -12), Vector3(0.8, 0.8, 0.8), Color(0.6, 0.65, 0.75)),
		# Signs + lamp posts + planters.
		PropData.make(PropData.PropType.SIGN, Vector3(-14, 0, 0), Vector3(1.4, 2.4, 1.0), Color(0.3, 0.5, 0.8)),
		PropData.make(PropData.PropType.SIGN, Vector3(14, 0, 0), Vector3(1.4, 2.4, 1.0), Color(0.3, 0.5, 0.8)),
		PropData.make(PropData.PropType.SIGN, Vector3(0, 0, -12), Vector3(1.6, 2.2, 1.0), Color(0.8, 0.7, 0.3)),
		PropData.make(PropData.PropType.SIGN, Vector3(-8, 0, 12), Vector3(1.2, 2.0, 1.0), Color(0.8, 0.6, 0.2)),
		PropData.make(PropData.PropType.SIGN, Vector3(8, 0, -12), Vector3(1.2, 2.0, 1.0), Color(0.8, 0.6, 0.2)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-4, 0, -8), Vector3(1.0, 3.0, 1.0), Color(0.9, 0.9, 0.8)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(4, 0, -8), Vector3(1.0, 3.0, 1.0), Color(0.9, 0.9, 0.8)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-4, 0, 8), Vector3(1.0, 3.0, 1.0), Color(0.9, 0.9, 0.8)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(4, 0, 8), Vector3(1.0, 3.0, 1.0), Color(0.9, 0.9, 0.8)),
		PropData.make(PropData.PropType.PLANTER, Vector3(-14, 0, -6), Vector3(1.2, 0.5, 1.2), Color(0.45, 0.5, 0.6)),
		PropData.make(PropData.PropType.PLANTER, Vector3(14, 0, 6), Vector3(1.2, 0.5, 1.2), Color(0.45, 0.5, 0.6)),
	]

	def.npc_spawns = [
		Vector3(-8, 0, -6), Vector3(-4, 0, 0), Vector3(0, 0, -4),
		Vector3(8, 0, 6), Vector3(4, 0, 0), Vector3(0, 0, 4),
		Vector3(-12, 0, 10), Vector3(12, 0, -10), Vector3(0, 0, 10),
		Vector3(-12, 0, -10), Vector3(12, 0, 10), Vector3(-4, 0, 12),
		Vector3(4, 0, -12),
	]
	return def
