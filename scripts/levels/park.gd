class_name ParkLevel
extends RefCounted
## Park level definition (M1b/M4): green park with a pavilion, trees, bushes
## (hiding spots), flowers, winding paths, a fountain, benches, lamp posts,
## signs, rocks, picnic tables and a kiosk, and a crowd of joggers/families.

static func create() -> LevelDefinition:
	var def := LevelDefinition.new()
	def.name = "Park"
	def.ground_size = Vector2(40.0, 40.0)
	def.ground_color = Color(0.3, 0.55, 0.25)
	def.ambient_color = Color(0.6, 0.8, 0.6)
	def.sun_color = Color(1.0, 1.0, 0.9)
	def.sun_intensity = 1.2
	def.sun_rotation = Vector3(-60.0, 25.0, 0.0)
	def.background_color = Color(0.45, 0.65, 0.55)
	def.glow_intensity = 0.1
	def.vignette_intensity = 0.06
	def.target_count = 3

	def.props = [
		# Pavilion + flag.
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -12), Vector3(8.0, 3.0, 5.0), Color(0.6, 0.45, 0.3), PropData.DoorSide.LEFT, 3),
		PropData.make(PropData.PropType.FLAG, Vector3(0, 0, -8), Vector3(1.2, 3.0, 1.0), Color(0.85, 0.3, 0.25), PropData.DoorSide.NONE, 0, 0.0, 0.12),
		# Trees around the perimeter.
		PropData.make(PropData.PropType.TREE, Vector3(-10, 0, -6), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(-6, 0, -8), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(10, 0, -6), Vector3(1.0, 4.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(6, 0, -8), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(-14, 0, -10), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(14, 0, -10), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(-8, 0, 14), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.55, 0.2)),
		# Bushes (hiding spots).
		PropData.make(PropData.PropType.BUSH, Vector3(-12, 0, 2), Vector3(1.4, 0.9, 1.4), Color(0.25, 0.5, 0.2)),
		PropData.make(PropData.PropType.BUSH, Vector3(12, 0, 2), Vector3(1.4, 0.9, 1.4), Color(0.25, 0.5, 0.2)),
		PropData.make(PropData.PropType.BUSH, Vector3(-12, 0, -2), Vector3(1.2, 0.8, 1.2), Color(0.3, 0.55, 0.25)),
		PropData.make(PropData.PropType.BUSH, Vector3(12, 0, -2), Vector3(1.2, 0.8, 1.2), Color(0.3, 0.55, 0.25)),
		PropData.make(PropData.PropType.BUSH, Vector3(-4, 0, 10), Vector3(1.2, 0.8, 1.2), Color(0.25, 0.5, 0.2)),
		# Flowers.
		PropData.make(PropData.PropType.FLOWER, Vector3(-10, 0, 4), Vector3(0.3, 0.3, 0.3), Color(0.95, 0.5, 0.7)),
		PropData.make(PropData.PropType.FLOWER, Vector3(10, 0, 4), Vector3(0.3, 0.3, 0.3), Color(0.9, 0.3, 0.3)),
		PropData.make(PropData.PropType.FLOWER, Vector3(-2, 0, 12), Vector3(0.3, 0.3, 0.3), Color(0.7, 0.4, 0.9)),
		# Fountain + winding paths.
		PropData.make(PropData.PropType.FOUNTAIN, Vector3(0, 0, 5), Vector3(2.4, 1.0, 2.4), Color(0.55, 0.55, 0.6)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(0, 0, 2), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.68, 0.5)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(0, 0, 3), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.68, 0.5)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(0, 0, 4), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.68, 0.5)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-2, 0, 0), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.68, 0.5)),
		PropData.make(PropData.PropType.PATH_TILE, Vector3(-4, 0, 0), Vector3(2.0, 0.05, 2.0), Color(0.75, 0.68, 0.5)),
		# Benches, picnic tables, table with umbrella.
		PropData.make(PropData.PropType.BENCH, Vector3(-8, 0, 6), Vector3(1.8, 0.9, 0.6), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.BENCH, Vector3(8, 0, 6), Vector3(1.8, 0.9, 0.6), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.BENCH, Vector3(-4, 0, -4), Vector3(1.8, 0.9, 0.6), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.PICNIC_TABLE, Vector3(-8, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.38, 0.25)),
		PropData.make(PropData.PropType.PICNIC_TABLE, Vector3(8, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.38, 0.25)),
		PropData.make(PropData.PropType.TABLE, Vector3(0, 0, 6), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.38, 0.25)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(0, 0, 6), Vector3(2.2, 2.4, 2.2), Color(0.9, 0.85, 0.3), PropData.DoorSide.NONE, 0, 0.0, 0.05),
		# Lamp posts, signs, rocks, trash can, kiosk, fence.
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-6, 0, 6), Vector3(1.0, 3.0, 1.0), Color(1.0, 0.9, 0.5)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(6, 0, 6), Vector3(1.0, 3.0, 1.0), Color(1.0, 0.9, 0.5)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-6, 0, -6), Vector3(1.0, 3.0, 1.0), Color(1.0, 0.9, 0.5)),
		PropData.make(PropData.PropType.SIGN, Vector3(-14, 0, 4), Vector3(1.4, 2.2, 1.0), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.ROCK, Vector3(-10, 0, 10), Vector3(1.2, 0.8, 1.0), Color(0.5, 0.5, 0.52)),
		PropData.make(PropData.PropType.ROCK, Vector3(10, 0, 10), Vector3(1.2, 0.8, 1.0), Color(0.5, 0.5, 0.52)),
		PropData.make(PropData.PropType.ROCK, Vector3(-2, 0, -8), Vector3(0.9, 0.6, 0.8), Color(0.5, 0.5, 0.52)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(-12, 0, 6), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.4, 0.3)),
		PropData.make(PropData.PropType.KIOSK, Vector3(-14, 0, 10), Vector3(2.5, 2.2, 1.8), Color(0.5, 0.4, 0.3)),
		PropData.make(PropData.PropType.FENCE, Vector3(0, 0, 16), Vector3(24.0, 1.0, 1.0), Color(0.6, 0.45, 0.3)),
	]

	def.npc_spawns = [
		Vector3(-4, 0, 4), Vector3(4, 0, 4), Vector3(-10, 0, 8),
		Vector3(10, 0, 8), Vector3(0, 0, 10), Vector3(-6, 0, -2),
		Vector3(6, 0, -2), Vector3(-14, 0, 12), Vector3(14, 0, 12),
		Vector3(-8, 0, -6), Vector3(8, 0, -6), Vector3(0, 0, -4),
		Vector3(-12, 0, 6), Vector3(12, 0, 6), Vector3(-2, 0, 8),
	]
	return def
