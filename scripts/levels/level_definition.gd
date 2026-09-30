class_name LevelDefinition
extends RefCounted
## Definition of a level: ground, lighting, props, NPC spawns (M1b).
## Consumed by LevelBuilder.build() to produce a Node3D scene.
## M3a: per-level mood fields — background color, glow/vignette intensity,
## optional subtle fog (background_color, glow_intensity, vignette_intensity).

var name: String = "Level"
var ground_size: Vector2 = Vector2(40.0, 40.0)
var ground_color: Color = Color(0.5, 0.5, 0.5)
var ambient_color: Color = Color(0.4, 0.4, 0.4)
var sun_color: Color = Color(1.0, 1.0, 1.0)
var sun_intensity: float = 1.0
var sun_rotation: Vector3 = Vector3(-50.0, 30.0, 0.0)  # degrees
# M3a: environment mood (sensible defaults; levels override).
var background_color: Color = Color(0.4, 0.5, 0.6)
var glow_intensity: float = 0.4
var vignette_intensity: float = 0.25
var fog_enabled: bool = false
var fog_color: Color = Color(0.5, 0.5, 0.5)
var fog_density: float = 0.01
var props: Array[PropData] = []
var npc_spawns: Array[Vector3] = []
var target_count: int = 2  # used by M2 hiding/photo targets
