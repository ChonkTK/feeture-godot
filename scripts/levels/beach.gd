class_name BeachLevel
extends RefCounted
## Beach level definition (M1b/M4): warm sunny seaside — boardwalk strip with
## shops/kiosks, rows of umbrellas + towels + coolers, lifeguard tower, dunes
## with fences, rocks, path tiles, lamp posts, signs, animated beach balls
## and flags, and a crowd of sunbathers/walkers.

static func create() -> LevelDefinition:
	var def := LevelDefinition.new()
	def.name = "Beach"
	def.ground_size = Vector2(40.0, 40.0)
	def.ground_color = Color(0.87, 0.8, 0.6)
	def.ambient_color = Color(1.0, 0.9, 0.7)
	def.sun_color = Color(1.0, 0.95, 0.8)
	def.sun_intensity = 1.4
	def.sun_rotation = Vector3(-55.0, 35.0, 0.0)
	def.background_color = Color(0.55, 0.75, 0.95)
	def.glow_intensity = 0.12
	def.vignette_intensity = 0.06
	def.target_count = 2

	def.props = [
		# Boardwalk strip (north edge) with shops, signs, lamps.
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-14, 0, 15), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.62, 0.45)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-10, 0, 15), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.62, 0.45)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-6, 0, 15), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.62, 0.45)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-2, 0, 15), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.62, 0.45)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(2, 0, 15), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.62, 0.45)),
		PropData.make(PropData.PropType.KIOSK, Vector3(-12, 0, 13), Vector3(3.0, 2.6, 2.0), Color(0.9, 0.5, 0.3)),
		PropData.make(PropData.PropType.KIOSK, Vector3(4, 0, 13), Vector3(2.5, 2.4, 1.8), Color(0.2, 0.6, 0.6)),
		PropData.make(PropData.PropType.SNACK_STAND, Vector3(12, 0, 13), Vector3(3.0, 2.4, 2.0), Color(0.85, 0.3, 0.25)),
		PropData.make(PropData.PropType.SIGN, Vector3(-9, 0, 13), Vector3(1.2, 2.2, 1.0), Color(0.6, 0.4, 0.25)),
		PropData.make(PropData.PropType.SIGN, Vector3(9, 0, 13), Vector3(1.2, 2.2, 1.0), Color(0.6, 0.4, 0.25)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-14, 0, 15), Vector3(1.0, 3.2, 1.0), Color(1.0, 0.85, 0.4)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-6, 0, 15), Vector3(1.0, 3.2, 1.0), Color(1.0, 0.85, 0.4)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(6, 0, 15), Vector3(1.0, 3.2, 1.0), Color(1.0, 0.85, 0.4)),
		PropData.make(PropData.PropType.FLAG, Vector3(16, 0, 13), Vector3(1.2, 3.0, 1.0), Color(0.9, 0.3, 0.2), PropData.DoorSide.NONE, 0, 0.0, 0.12),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(8, 0, 13), Vector3(0.5, 0.9, 0.5), Color(0.4, 0.4, 0.42)),
		PropData.make(PropData.PropType.PLANTER, Vector3(10, 0, 11), Vector3(1.2, 0.5, 1.2), Color(0.7, 0.45, 0.3)),
		# Lifeguard tower + restroom + beach house.
		PropData.make(PropData.PropType.LIFEGUARD_TOWER, Vector3(-14, 0, -10), Vector3(2.5, 4.5, 2.5), Color(0.8, 0.4, 0.2)),
		PropData.make(PropData.PropType.RESTROOM, Vector3(-8, 0, 12), Vector3(4.0, 2.6, 3.0), Color(0.85, 0.85, 0.8), PropData.DoorSide.FRONT, 1),
		PropData.make(PropData.PropType.BUILDING, Vector3(12, 0, -4), Vector3(5.0, 3.0, 4.0), Color(0.95, 0.9, 0.8), PropData.DoorSide.BACK, 3),
		# Sunbathing row: umbrellas, towels, coolers, bobbing beach balls.
		PropData.make(PropData.PropType.UMBRELLA, Vector3(-8, 0, -6), Vector3(2.4, 2.6, 2.4), Color(1.0, 0.3, 0.3), PropData.DoorSide.NONE, 0, 0.0, 0.05),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(-4, 0, -6), Vector3(2.4, 2.6, 2.4), Color(0.3, 0.6, 1.0)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(0, 0, -6), Vector3(2.4, 2.6, 2.4), Color(1.0, 0.9, 0.2)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(4, 0, -6), Vector3(2.4, 2.6, 2.4), Color(0.2, 0.7, 0.4)),
		PropData.make(PropData.PropType.TOWEL, Vector3(-8, 0, -4.5), Vector3(1.6, 0.05, 1.0), Color(0.95, 0.4, 0.4)),
		PropData.make(PropData.PropType.TOWEL, Vector3(-4, 0, -4.5), Vector3(1.6, 0.05, 1.0), Color(0.4, 0.6, 0.95)),
		PropData.make(PropData.PropType.TOWEL, Vector3(0, 0, -4.5), Vector3(1.6, 0.05, 1.0), Color(0.95, 0.9, 0.4)),
		PropData.make(PropData.PropType.TOWEL, Vector3(4, 0, -4.5), Vector3(1.6, 0.05, 1.0), Color(0.4, 0.8, 0.5)),
		PropData.make(PropData.PropType.COOLER, Vector3(-7, 0, -3), Vector3(0.8, 0.6, 0.8), Color(0.9, 0.9, 0.9)),
		PropData.make(PropData.PropType.COOLER, Vector3(-3, 0, -3), Vector3(0.8, 0.6, 0.8), Color(0.9, 0.9, 0.9)),
		PropData.make(PropData.PropType.COOLER, Vector3(1, 0, -3), Vector3(0.8, 0.6, 0.8), Color(0.9, 0.9, 0.9)),
		PropData.make(PropData.PropType.COOLER, Vector3(5, 0, -3), Vector3(0.8, 0.6, 0.8), Color(0.9, 0.9, 0.9)),
		PropData.make(PropData.PropType.BEACH_BALL, Vector3(-6, 0, -7), Vector3(0.5, 0.5, 0.5), Color(0.95, 0.3, 0.3), PropData.DoorSide.NONE, 0, 0.15),
		PropData.make(PropData.PropType.BEACH_BALL, Vector3(2, 0, -7), Vector3(0.5, 0.5, 0.5), Color(0.3, 0.6, 0.95), PropData.DoorSide.NONE, 0, 0.12),
		PropData.make(PropData.PropType.BENCH, Vector3(-6, 0, -2), Vector3(1.8, 0.9, 0.6), Color(0.6, 0.4, 0.25)),
		# Dunes with fence (south-west), rocks along the water, trees.
		PropData.make(PropData.PropType.DUNE, Vector3(-16, 0, 8), Vector3(4.0, 1.2, 3.0), Color(0.8, 0.72, 0.5)),
		PropData.make(PropData.PropType.DUNE, Vector3(-18, 0, 12), Vector3(5.0, 1.4, 3.5), Color(0.8, 0.72, 0.5)),
		PropData.make(PropData.PropType.FENCE, Vector3(-16, 0, 10), Vector3(8.0, 1.0, 1.0), Color(0.75, 0.6, 0.4)),
		PropData.make(PropData.PropType.ROCK, Vector3(16, 0, -16), Vector3(1.2, 0.8, 1.0), Color(0.55, 0.55, 0.58)),
		PropData.make(PropData.PropType.ROCK, Vector3(18, 0, -14), Vector3(0.9, 0.6, 0.8), Color(0.55, 0.55, 0.58)),
		PropData.make(PropData.PropType.ROCK, Vector3(14, 0, -18), Vector3(1.4, 0.9, 1.1), Color(0.55, 0.55, 0.58)),
		PropData.make(PropData.PropType.TREE, Vector3(14, 0, 8), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.6, 0.25)),
		PropData.make(PropData.PropType.TREE, Vector3(16, 0, 10), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.6, 0.25)),
		PropData.make(PropData.PropType.TREE, Vector3(-4, 0, 16), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.6, 0.25)),
		PropData.make(PropData.PropType.FLOWER, Vector3(-6, 0, 10), Vector3(0.3, 0.3, 0.3), Color(0.95, 0.5, 0.7)),
		PropData.make(PropData.PropType.FLOWER, Vector3(-10, 0, 10), Vector3(0.3, 0.3, 0.3), Color(0.95, 0.85, 0.3)),
		PropData.make(PropData.PropType.BUSH, Vector3(-14, 0, 4), Vector3(1.2, 0.8, 1.2), Color(0.25, 0.55, 0.2)),
	]

	def.npc_spawns = [
		Vector3(-10, 0, -8), Vector3(-2, 0, -4), Vector3(6, 0, -8),
		Vector3(12, 0, 2), Vector3(-12, 0, 6), Vector3(0, 0, 10),
		Vector3(8, 0, 12), Vector3(-4, 0, 14), Vector3(14, 0, -10),
		Vector3(-16, 0, 4), Vector3(16, 0, 6), Vector3(-2, 0, 12),
		Vector3(10, 0, 6), Vector3(-14, 0, -4),
	]
	return def
