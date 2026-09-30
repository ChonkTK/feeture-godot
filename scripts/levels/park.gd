class_name ParkLevel
extends RefCounted
## Park level definition (M1b): green park with a pavilion, trees, bushes,
## benches, a picnic table with umbrella and a perimeter fence.

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
	def.glow_intensity = 0.4
	def.vignette_intensity = 0.2
	def.target_count = 3

	def.props = [
		PropData.make(PropData.PropType.BUILDING, Vector3(0, 0, -12), Vector3(8.0, 3.0, 5.0), Color(0.6, 0.45, 0.3), PropData.DoorSide.LEFT, 3),
		PropData.make(PropData.PropType.TREE, Vector3(-10, 0, -6), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(-6, 0, -8), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(10, 0, -6), Vector3(1.0, 4.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.TREE, Vector3(6, 0, -8), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.55, 0.2)),
		PropData.make(PropData.PropType.BUSH, Vector3(-12, 0, 2), Vector3(1.4, 0.9, 1.4), Color(0.25, 0.5, 0.2)),
		PropData.make(PropData.PropType.BUSH, Vector3(12, 0, 2), Vector3(1.4, 0.9, 1.4), Color(0.25, 0.5, 0.2)),
		PropData.make(PropData.PropType.BUSH, Vector3(-12, 0, -2), Vector3(1.2, 0.8, 1.2), Color(0.3, 0.55, 0.25)),
		PropData.make(PropData.PropType.BUSH, Vector3(12, 0, -2), Vector3(1.2, 0.8, 1.2), Color(0.3, 0.55, 0.25)),
		PropData.make(PropData.PropType.BENCH, Vector3(-8, 0, 6), Vector3(1.8, 0.9, 0.6), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.BENCH, Vector3(8, 0, 6), Vector3(1.8, 0.9, 0.6), Color(0.55, 0.4, 0.25)),
		PropData.make(PropData.PropType.TABLE, Vector3(0, 0, 6), Vector3(1.6, 0.8, 1.6), Color(0.5, 0.38, 0.25)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(0, 0, 6), Vector3(2.2, 2.4, 2.2), Color(0.9, 0.85, 0.3)),
		PropData.make(PropData.PropType.FENCE, Vector3(0, 0, 16), Vector3(24.0, 1.0, 1.0), Color(0.6, 0.45, 0.3)),
		PropData.make(PropData.PropType.KIOSK, Vector3(-14, 0, 10), Vector3(2.5, 2.2, 1.8), Color(0.5, 0.4, 0.3)),
	]

	def.npc_spawns = [
		Vector3(-4, 0, 4), Vector3(4, 0, 4), Vector3(-10, 0, 8),
		Vector3(10, 0, 8), Vector3(0, 0, 10), Vector3(-6, 0, -2),
		Vector3(6, 0, -2), Vector3(-14, 0, 12), Vector3(14, 0, 12),
	]
	return def
