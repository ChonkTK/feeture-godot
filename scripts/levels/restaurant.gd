class_name RestaurantLevel
extends RefCounted
## Restaurant level definition (M1b): moody dining room with a main building,
## tables/chairs, snack stand, partitions and a perimeter fence.

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
	def.glow_intensity = 0.45
	def.vignette_intensity = 0.4
	def.crowd_volume = 0.6
	def.fog_enabled = true
	def.fog_color = Color(0.4, 0.25, 0.15)
	def.fog_density = 0.015
	def.target_count = 2

	def.props = [
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -12), Vector3(12.0, 3.2, 6.0), Color(0.4, 0.28, 0.2), PropData.DoorSide.FRONT, 4),
		PropData.make(PropData.PropType.SNACK_STAND, Vector3(-10, 0, 8), Vector3(3.0, 2.4, 2.0), Color(0.55, 0.35, 0.2)),
		PropData.make(PropData.PropType.TABLE, Vector3(-6, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(0, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.TABLE, Vector3(6, 0, -2), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.35, 0.22)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-6.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-5.2, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(0.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(-0.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(6.8, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.CHAIR, Vector3(5.2, 0, -2.8), Vector3(0.5, 0.9, 0.5), Color(0.35, 0.25, 0.18)),
		PropData.make(PropData.PropType.PARTITION, Vector3(-3, 0, 4), Vector3(4.0, 1.6, 0.12), Color(0.45, 0.3, 0.2)),
		PropData.make(PropData.PropType.PARTITION, Vector3(3, 0, 4), Vector3(4.0, 1.6, 0.12), Color(0.45, 0.3, 0.2)),
		PropData.make(PropData.PropType.FENCE, Vector3(0, 0, 14), Vector3(20.0, 1.0, 1.0), Color(0.4, 0.28, 0.2)),
		PropData.make(PropData.PropType.BENCH, Vector3(-12, 0, -6), Vector3(2.0, 0.9, 0.6), Color(0.45, 0.3, 0.2)),
	]

	def.npc_spawns = [
		Vector3(-4, 0, 0), Vector3(4, 0, 0), Vector3(-8, 0, 4),
		Vector3(8, 0, 4), Vector3(0, 0, 6), Vector3(-12, 0, 10),
		Vector3(12, 0, 10), Vector3(-6, 0, 12), Vector3(6, 0, 12),
	]
	return def
