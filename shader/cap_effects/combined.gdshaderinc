#ifndef CAP_EFFECTS_COMBINED
#define CAP_EFFECTS_COMBINED

#include "res://shader/cap_effects/metal.gdshaderinc"
#include "res://shader/cap_effects/invisible.gdshaderinc"

group_uniforms metal.rim;
uniform vec4 metal_accent : source_color = vec4(0.61, 0.74, 1.0, 1.0);
uniform float metal_accent_strength : hint_range(0.0, 1.0, 0.05) = 0.3;
uniform float metal_rim : hint_range(0.0, 1.0, 0.05) = 0.75;
uniform vec2 metal_light_direction = vec2(-1.0, -1.0);
group_uniforms invisible.edge;
uniform vec4 invisible_edge_color : source_color = vec4(0.88, 0.96, 1.0, 1.0);
uniform float invisible_edge_alpha : hint_range(0.0, 1.0, 0.01) = 0.7;
group_uniforms invisible.fringe;
uniform vec4 invisible_fringe_warm : source_color = vec4(1.0, 0.35, 0.7, 1.0);
uniform vec4 invisible_fringe_cool : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform float invisible_fringe_alpha : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float invisible_fringe_offset : hint_range(0.0, 4.0, 1.0) = 1.0;
group_uniforms;


struct CapSamples {
	float rim;
	float right;
	float left;
	float down;
	float up;
	float warm;
	float cool;
};


#define CAP_SOLID(source, uv) step(0.5, textureLod(source, uv, 0.0).a)
#define CAP_SAMPLES(source, uv, pixel, facing) CapSamples(CAP_SOLID(source, (uv) + cap_rim_offset(facing, pixel)), CAP_SOLID(source, (uv) + vec2((pixel).x, 0.0)), CAP_SOLID(source, (uv) - vec2((pixel).x, 0.0)), CAP_SOLID(source, (uv) + vec2(0.0, (pixel).y)), CAP_SOLID(source, (uv) - vec2(0.0, (pixel).y)), CAP_SOLID(source, (uv) + cap_fringe_offset(pixel)), CAP_SOLID(source, (uv) - cap_fringe_offset(pixel)))


vec2 cap_rim_offset(float facing, vec2 pixel) {
	vec2 light = metal_light_direction * vec2(facing, 1.0);
	return round(light / max(max(abs(light.x), abs(light.y)), 0.0001)) * pixel;
}


vec2 cap_fringe_offset(vec2 pixel) {
	return vec2(invisible_fringe_offset * pixel.x, 0.0);
}


vec3 metal_effect_with_rim(vec3 rgb, float rim_solid, vec2 position, float facing) {
	float rim = 1.0 - rim_solid;
	vec3 accent = mix(vec3(1.0), metal_accent.rgb, metal_accent_strength);
	vec3 metal = metal_effect(rgb, position * vec2(facing, 1.0));
	return min(metal + accent * rim * metal_rim, vec3(1.0));
}


vec4 invisible_effect_with_edges(vec3 rgb, float mask, CapSamples samples, vec2 position) {
	float neighbours = min(min(samples.right, samples.left), min(samples.down, samples.up));
	float edge = mask * (1.0 - neighbours);
	float stripe = invisible_stripe_at(position.y);
	
	vec3 body = invisible_tinted(rgb);
	body = mix(body, invisible_edge_color.rgb, max(edge, stripe * invisible_stripe_brightness));
	float body_out = mask * mix(invisible_alpha(stripe), invisible_edge_alpha, edge);
	
	float warm = max(samples.warm - mask, 0.0) * invisible_fringe_alpha;
	float cool = max(samples.cool - mask, 0.0) * invisible_fringe_alpha;
	float fringe_out = max(warm, cool);
	vec3 fringe = (
		(invisible_fringe_warm.rgb * warm + invisible_fringe_cool.rgb * cool)
		/ max(warm + cool, 0.0001)
	);
	
	float alpha = body_out + fringe_out * (1.0 - body_out);
	return vec4(
		(body * body_out + fringe * fringe_out * (1.0 - body_out)) / max(alpha, 0.0001),
		alpha
	);
}


vec4 cap_effect(
	CapSamples samples,
	vec4 color,
	vec2 position,
	float metal_mix,
	float facing,
	float invisible_mix,
	bool exempt
) {
	vec4 result = color;
	if (metal_mix > 0.0 && !exempt) {
		result.rgb = mix(result.rgb, metal_effect_with_rim(result.rgb, samples.rim, position, facing), metal_mix);
	}
	if (invisible_mix > 0.0) {
		vec4 ghost = invisible_effect_with_edges(result.rgb, step(0.5, color.a), samples, position);
		result = mix(result, ghost, invisible_mix);
	}
	return result;
}

#endif
