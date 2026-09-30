// Toon/cel shader (M3a). Lit (NOT unshaded): banded diffuse from the
// directional sun, fresnel rim light, and a subtle fresnel edge-darkening
// "outline" — all in a single pass. Single-pass fresnel edge darkening was
// chosen over a second cull_front pass on a scaled duplicate mesh because it
// is the most robust for Godot 4.7: no extra draw call, no mesh duplication,
// no depth/z-fighting artifacts, and it scales correctly on the NPC's tiny
// parts (toes, pupils) where a world-space outline would blob out.
//
// Godot 4.7 gotchas handled here: no saturate() (use clamp), and RIM_TINT is
// a float scalar (not vec3), so the colored rim is added to DIFFUSE_LIGHT in
// light() instead of using the RIM/RIM_TINT outputs.
shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int toon_steps : hint_range(1, 8) = 3;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.35;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float outline_width : hint_range(0.0, 1.0) = 0.3;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float glossy : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Subtle outline: fresnel edge darkening. outline_width widens the band
	// (higher width -> lower fresnel power -> wider band).
	float edge_power = 1.0 + (1.0 - outline_width) * 12.0;
	float edge = pow(1.0 - ndv, edge_power);
	ALBEDO = mix(albedo_color.rgb, outline_color.rgb, edge * outline_strength);
}

void light() {
	// Banded (toon) diffuse: quantize NdotL into toon_steps bands.
	float ndl = dot(NORMAL, LIGHT);
	float band = floor(clamp(ndl, 0.0, 1.0) * float(toon_steps)) / float(toon_steps);
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR;
	// Fresnel rim light (smooth, warm tint) — brightens silhouette edges.
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	DIFFUSE_LIGHT += rim_amount * fres * rim_color.rgb * LIGHT_COLOR * ATTENUATION;
	// Small glossy specular highlight (feet use glossy > 0).
	if (glossy > 0.001) {
		vec3 half_dir = normalize(LIGHT + VIEW);
		float ndh = max(dot(NORMAL, half_dir), 0.0);
		float spec = pow(ndh, 24.0) * glossy;
		SPECULAR_LIGHT += spec * ATTENUATION * LIGHT_COLOR;
	}
}
