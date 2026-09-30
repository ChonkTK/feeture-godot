class_name PropData
extends RefCounted
## Data describing a single prop placed in a level (M1b).
## M4: new decorative types (lamp posts, planters, signs, rocks, flowers,
## path tiles, fountain, trash cans, towels, coolers, beach balls, pillars,
## booths, bar, picnic tables, dunes, flags) + bob/sway ambient animation.

enum PropType {
	CUBE, SPHERE, CAPSULE, CYLINDER, PLANE,
	BUILDING, WALL, FENCE, KIOSK, LIFEGUARD_TOWER,
	RESTROOM, SNACK_STAND, TICKET_BOOTH, PARTITION,
	BENCH, TABLE, CHAIR, TREE, BUSH, UMBRELLA,
	LAMP_POST, PLANTER, SIGN, ROCK, FLOWER, PATH_TILE,
	FOUNTAIN, TRASH_CAN, TOWEL, COOLER, BEACH_BALL,
	PILLAR, BOOTH, BAR, PICNIC_TABLE, DUNE, FLAG,
}

enum DoorSide {
	NONE, FRONT, BACK, LEFT, RIGHT,
}

var type: PropType = PropType.CUBE
var position: Vector3 = Vector3.ZERO
var scale: Vector3 = Vector3.ONE
var color: Color = Color.WHITE
var door_side: DoorSide = DoorSide.NONE
var window_count: int = 0
# M4: ambient animation amplitudes (0 = static). bob is meters, sway is radians.
var bob: float = 0.0
var sway: float = 0.0


## Factory for compact level definitions.
static func make(
	p_type: PropType,
	p_position: Vector3,
	p_scale: Vector3 = Vector3.ONE,
	p_color: Color = Color.WHITE,
	p_door_side: DoorSide = DoorSide.NONE,
	p_window_count: int = 0,
	p_bob: float = 0.0,
	p_sway: float = 0.0,
) -> PropData:
	var p := PropData.new()
	p.type = p_type
	p.position = p_position
	p.scale = p_scale
	p.color = p_color
	p.door_side = p_door_side
	p.window_count = p_window_count
	p.bob = p_bob
	p.sway = p_sway
	return p
