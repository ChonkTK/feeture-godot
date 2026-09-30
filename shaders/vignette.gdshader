// Vignette post-process overlay (M3a). Godot 4.7 removed Environment's
// vignette_* properties (a Godot 3 API), so the vignette is implemented as a
// fullscreen screen-space overlay: a ColorRect in a CanvasLayer that darkens
// the edges of the rendered 3D scene. Intensity is per-level.
// Godot 4.7 gotcha: SCREEN_TEXTURE is no longer a built-in — it must be
// declared as a hint_screen_texture uniform.
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.25;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 centered = SCREEN_UV - vec2(0.5);
	float dist = length(centered) * 1.41421356;  // 0 at center .. 1 at corners
	float vig = smoothstep(0.35, 0.9, dist) * intensity;
	vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	col = mix(col, vignette_color.rgb, vig);
	COLOR = vec4(col, 1.0);
}
