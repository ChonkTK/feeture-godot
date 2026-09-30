class_name BeachLevel
extends RefCounted
## Beach level definition (M1b): warm sunny seaside with lifeguard tower,
## kiosk, restroom, umbrellas, trees and a boardwalk fence.

static func create() -> LevelDefinition:
	var def := LevelDefinition.new()
	def.name = "Beach"
	def.ground_size = Vector2(40.0, 40.0)
	def.ground_color = Color(0.87, 0.8, 0.6)
	def.ambient_color = Color(1.0, 0.9, 0.7)
	def.sun_color = Color(1.0, 0.95, 0.8)
	def.sun_intensity = 1.4
	def.sun_rotation = Vector3(-55.0, 35.0, 0.0)
	def.target_count = 2

	def.props = [
		PropData.make(PropData.PropType.LIFEGUARD_TOWER, Vector3(-12, 0, -10), Vector3(2.5, 4.5, 2.5), Color(0.8, 0.4, 0.2)),
		PropData.make(PropData.PropType.KIOSK, Vector3(10, 0, -12), Vector3(3.0, 2.6, 2.0), Color(0.9, 0.5, 0.3)),
		PropData.make(PropData.PropType.RESTROOM, Vector3(-8, 0, 12), Vector3(4.0, 2.6, 3.0), Color(0.85, 0.85, 0.8), PropData.DoorSide.FRONT, 1),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(-4, 0, -6), Vector3(2.4, 2.6, 2.4), Color(1.0, 0.3, 0.3)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(0, 0, -8), Vector3(2.4, 2.6, 2.4), Color(0.3, 0.6, 1.0)),
		PropData.make(PropData.PropType.UMBRELLA, Vector3(4, 0, -6), Vector3(2.4, 2.6, 2.4), Color(1.0, 0.9, 0.2)),
		PropData.make(PropData.PropType.BENCH, Vector3(-6, 0, -2), Vector3(1.8, 0.9, 0.6), Color(0.6, 0.4, 0.25)),
		PropData.make(PropData.PropType.TREE, Vector3(14, 0, 8), Vector3(1.0, 4.0, 1.0), Color(0.2, 0.6, 0.25)),
		PropData.make(PropData.PropType.TREE, Vector3(16, 0, 10), Vector3(1.0, 3.5, 1.0), Color(0.2, 0.6, 0.25)),
		PropData.make(PropData.PropType.FENCE, Vector3(0, 0, 16), Vector3(16.0, 1.0, 1.0), Color(0.75, 0.6, 0.4)),
		PropData.make(PropData.PropType.BUILDING, Vector3(12, 0, -4), Vector3(5.0, 3.0, 4.0), Color(0.95, 0.9, 0.8), PropData.DoorSide.BACK, 3),
		PropData.make(PropData.PropType.BUSH, Vector3(-14, 0, 4), Vector3(1.2, 0.8, 1.2), Color(0.25, 0.55, 0.2)),
	]

	def.npc_spawns = [
		Vector3(-10, 0, -8), Vector3(-2, 0, -4), Vector3(6, 0, -8),
		Vector3(12, 0, 2), Vector3(-12, 0, 6), Vector3(0, 0, 10),
		Vector3(8, 0, 12), Vector3(-4, 0, 14), Vector3(14, 0, -10),
	]
	return def
