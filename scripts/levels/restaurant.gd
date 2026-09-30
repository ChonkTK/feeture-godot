class_name RestaurantLevel
extends RefCounted
## Restaurant level definition (M1b/M4): moody dining room — main building with
## kitchen wall, many tables/chairs, booths, a bar, plants, partitions, lamp
## posts, signs and trash cans, and a crowd of diners/waiters.

static func create() -> LevelDefinition:
	var def := LevelDefinition.new()
	def.name = "Restaurant"
	def.ground_size = Vector2(40.0, 40.0)
	def.ground_color = Color(0.2, 0.16, 0.14)
	def.ambient_color = Color(0.5, 0.35, 0.25)
	def.sun_color = Color(1.0, 0.8, 0.6)
	def.sun_intensity = 0.5
	def.sun_rotation = Vector3(-30.0, 45.0, 0.0)
	def.background_color = Color(0.12, 0.08, 0.06)
	def.glow_intensity = 0.12
	def.vignette_intensity = 0.12
	def.target_count = 2

	def.props = [
		# Main building + kitchen wall (two partitions with a walkable gap).
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -12), Vector3(12.0, 3.2, 6.0), Color(0.4, 0.28, 0.2), PropData.DoorSide.FRONT, 4),
		PropData.make(PropData.PropType.PARTITION, Vector3(-3.5, 0, -6.5), Vector3(4.0, 2.4, 0.15), Color(0.45, 0.32, 0.22)),
		PropData.make(PropData.PropType.PARTITION, Vector3(3.5, 0, -6.5), Vector3(4.0, 2.4, 0.15), Color(0.45, 0.32, 0.22)),
		# Dining tables with chairs.
		PropData.make(PropData.PropType.TABLE, Vector3(-6, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(0, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(6, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(-6, 0, 2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(0, 0, 2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(6, 0, 2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-6.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-5.2, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(0.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-0.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(6.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(5.2, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-6.8, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-5.2, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(0.8, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-0.8, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(6.8, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(5.2, 0, 1.2), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		# Booths along the sides.
		PropData.make(PropData.PropType.BOOTH, Vector3(-9, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.6, 0.25, 0.2)),
		PropData.make(PropData.PropType.BOOTH, Vector3(9, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.6, 0.25, 0.2)),
		PropData.make(PropData.PropType.BOOTH, Vector3(-9, 0, 2), Vector3(1.6, 0.8, 1.6), Color(0.25, 0.4, 0.6)),
		PropData.make(PropData.PropType.BOOTH, Vector3(9, 0, 2), Vector3(1.6, 0.8, 1.6), Color(0.25, 0.4, 0.6)),
		# Bar with stools.
		PropData.make(PropData.PropType.BAR, Vector3(10, 0, -8), Vector3(4.0, 1.1, 1.2), Color(0.35, 0.22, 0.15)),
		PropData.make(PropData.PropType.CHAIR, Vector3(10.8, 0, -6.2), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.2, 0.15)),
		PropData.make(PropData.PropType.CHAIR, Vector3(9.2, 0, -6.2), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.2, 0.15)),
		# Partitions, plants, lamps, signs.
		PropData.make(PropData.PropType.PARTITION, Vector3(-3, 0, 4), Vector3(4.0, 1.6, 0.12), Color(0.45, 0.3, 0.2)),
		PropData.make(PropData.PropType.PARTITION, Vector3(3, 0, 4), Vector3(4.0, 1.6, 0.12), Color(0.45, 0.3, 0.2)),
		PropData.make(PropData.PropType.PLANTER, Vector3(-11, 0, 6), Vector3(1.2, 0.5, 1.2), Color(0.55, 0.35, 0.2)),
		PropData.make(PropData.PropType.PLANTER, Vector3(11, 0, 6), Vector3(1.2, 0.5, 1.2), Color(0.55, 0.35, 0.2)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(-8, 0, 6), Vector3(1.0, 2.8, 1.0), Color(1.0, 0.8, 0.5)),
		PropData.make(PropData.PropType.LAMP_POST, Vector3(8, 0, 6), Vector3(1.0, 2.8, 1.0), Color(1.0, 0.8, 0.5)),
		PropData.make(PropData.PropType.SIGN, Vector3(0, 0, 6), Vector3(2.0, 2.4, 1.0), Color(0.7, 0.25, 0.2)),
		PropData.make(PropData.PropType.SIGN, Vector3(-12, 0, 10), Vector3(1.2, 2.2, 1.0), Color(0.5, 0.35, 0.2)),
		PropData.make(PropData.PropType.FLOWER, Vector3(-10, 0, 4), Vector3(0.3, 0.3, 0.3), Color(0.9, 0.5, 0.6)),
		PropData.make(PropData.PropType.FLOWER, Vector3(10, 0, 4), Vector3(0.3, 0.3, 0.3), Color(0.95, 0.85, 0.3)),
		# Snack stand, trash cans, bench, perimeter fence.
		PropData.make(PropData.PropType.SNACK_STAND, Vector3(-10, 0, 8), Vector3(3.0, 2.4, 2.0), Color(0.55, 0.35, 0.2)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(-12, 0, 12), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.28, 0.25)),
		PropData.make(PropData.PropType.TRASH_CAN, Vector3(12, 0, 12), Vector3(0.5, 0.9, 0.5), Color(0.3, 0.28, 0.25)),
		PropData.make(PropData.PropType.BENCH, Vector3(-12, 0, -6), Vector3(2.0, 0.9, 0.6), Color(0.45, 0.3, 0.2)),
		PropData.make(PropData.PropType.FENCE, Vector3(0, 0, 14), Vector3(20.0, 1.0, 1.0), Color(0.4, 0.28, 0.2)),
	]

	def.npc_spawns = [
		Vector3(-4, 0, 0), Vector3(4, 0, 0), Vector3(-8, 0, 4),
		Vector3(8, 0, 4), Vector3(0, 0, 6), Vector3(-12, 0, 10),
		Vector3(12, 0, 10), Vector3(-6, 0, 12), Vector3(6, 0, 12),
		Vector3(-10, 0, -4), Vector3(10, 0, -4), Vector3(0, 0, -8),
		Vector3(-4, 0, 8), Vector3(4, 0, 8),
	]
	return def
