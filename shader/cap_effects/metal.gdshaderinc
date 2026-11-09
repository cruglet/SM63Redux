#ifndef CAP_EFFECTS_METAL
#define CAP_EFFECTS_METAL

#include "res://shader/cap_effects/common.gdshaderinc"
#include "res://shader/cap_effects/metal_mark.gdshaderinc"

group_uniforms metal;
uniform sampler2D metal_ramp : source_color, filter_linear, repeat_disable;
uniform vec4 metal_tint : source_color = vec4(0.85, 0.9, 1.0, 1.0);
uniform float metal_contrast : hint_range(0.5, 3.0, 0.05) = 1.25;
uniform float metal_sheen : hint_range(0.0, 1.0, 0.05) = 0.35;
uniform float metal_sheen_width : hint_range(1.0, 32.0, 1.0) = 5.0;
uniform float metal_sheen_interval = 180.0;
uniform float metal_sheen_speed = 60.0;
uniform float metal_sheen_slant = 0.6;
group_uniforms;


float metal_sheen_at(vec2 position) {
	vec2 pixel = floor(position);
	float band = pixel.x + pixel.y * metal_sheen_slant - TIME * metal_sheen_speed;
	float distance_to_band = abs(
		mod(band, metal_sheen_interval) - metal_sheen_interval * 0.5
	);
	return 1.0 - smoothstep(0.0, metal_sheen_width, distance_to_band);
}


vec3 metal_effect(vec3 rgb, vec2 position) {
	float lum = clamp((cap_luminance(rgb) - 0.5) * metal_contrast + 0.5, 0.0, 1.0);
	vec3 metal = texture(metal_ramp, vec2(lum, 0.5)).rgb * metal_tint.rgb;
	metal += metal_sheen_at(position) * metal_sheen;
	return min(metal, vec3(1.0));
}

#endif
