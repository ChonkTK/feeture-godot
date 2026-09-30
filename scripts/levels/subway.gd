class_name SubwayLevel
extends RefCounted
## Subway level definition (M1b): cool underground platform with ticket booth,
## flanking walls, partitions, benches and a kiosk.

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
	def.glow_intensity = 0.3
	def.vignette_intensity = 0.35
	def.fog_enabled = true
	def.fog_color = Color(0.3, 0.4, 0.6)
	def.fog_density = 0.02
	def.target_count = 2

	def.props = [
		PropData.make(PropData.PropType.TICKET_BOOTH, Vector3(-10, 0, -10), Vector3(3.0, 2.4, 2.0), Color(0.4, 0.45, 0.55)),
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -14), Vector3(10.0, 3.0, 2.0), Color(0.35, 0.38, 0.45), PropData.DoorSide.FRONT, 2),
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, 14), Vector3(10.0, 3.0, 2.0), Color(0.35, 0.38, 0.45), PropData.DoorSide.BACK, 2),
		PropData.make(PropData.PropType.WALL, Vector3(-16, 0, 0), Vector3(1.0, 2.4, 20.0), Color(0.45, 0.5, 0.6)),
		PropData.make(PropData.PropType.WALL, Vector3(16, 0, 0), Vector3(1.0, 2.4, 20.0), Color(0.45, 0.5, 0.6)),
		PropData.make(PropData.PropType.PARTITION, Vector3(-6, 0, 4), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.PARTITION, Vector3(6, 0, -4), Vector3(3.0, 1.8, 0.15), Color(0.5, 0.55, 0.65)),
		PropData.make(PropData.PropType.BENCH, Vector3(-12, 0, 6), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.BENCH, Vector3(12, 0, -6), Vector3(2.0, 0.9, 0.6), Color(0.3, 0.4, 0.5)),
		PropData.make(PropData.PropType.KIOSK, Vector3(10, 0, 10), Vector3(2.5, 2.2, 1.8), Color(0.55, 0.6, 0.7)),
		PropData.make(PropData.PropType.CUBE, Vector3(-4, 0, 8), Vector3(1.0, 1.0, 1.0), Color(0.6, 0.65, 0.75)),
		PropData.make(PropData.PropType.CUBE, Vector3(4, 0, -8), Vector3(1.0, 1.0, 1.0), Color(0.6, 0.65, 0.75)),
	]

	def.npc_spawns = [
		Vector3(-8, 0, -6), Vector3(-4, 0, 0), Vector3(0, 0, -4),
		Vector3(8, 0, 6), Vector3(4, 0, 0), Vector3(0, 0, 4),
		Vector3(-12, 0, 10), Vector3(12, 0, -10), Vector3(0, 0, 10),
	]
	return def
