#include "res://shader/cap_effects/metal.gdshaderinc"
#include "res://shader/cap_effects/invisible.gdshaderinc"

uniform float outline_width : hint_range(0.5, 4.0, 0.5) = 2.0;
uniform float fill_top : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float fill_bottom : hint_range(0.0, 1.0, 0.001) = 1.0;
group_uniforms metal.progress;
uniform float metal_progress : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform vec4 metal_outline : source_color = vec4(0.12, 0.13, 0.17, 1.0);
group_uniforms invisible.progress;
uniform float invisible_progress : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform vec4 invisible_outline : source_color = vec4(0.88, 0.96, 1.0, 1.0);
group_uniforms;


float hud_radial_mask(vec2 offset, float progress) {
	float angle = mod(atan(-offset.x, -offset.y) + TAU, TAU);
	return step(angle, progress * TAU) * step(0.0001, progress);
}


float hud_ray(vec2 offset, float angle) {
	vec2 direction = vec2(-sin(angle), -cos(angle));
	float cross_distance = abs(offset.x * direction.y - offset.y * direction.x);
	return step(cross_distance, outline_width * 0.5) * step(0.0, dot(offset, direction));
}


float hud_radial_edge(vec2 offset, float progress) {
	if (progress <= 0.0001 || progress >= 0.9999) {
		return 0.0;
	}
	
	return max(hud_ray(offset, 0.0), hud_ray(offset, progress * TAU));
}


float hud_vertical_depth(vec2 pixel, float height, float progress) {
	float bottom = fill_bottom * height;
	return pixel.y + 0.5 - (bottom - progress * (bottom - fill_top * height));
}


float hud_vertical_mask(vec2 pixel, float height, float progress) {
	return step(0.0, hud_vertical_depth(pixel, height, progress)) * step(0.0001, progress);
}


float hud_vertical_edge(vec2 pixel, float height, float progress) {
	if (progress <= 0.0001 || progress >= 0.9999) {
		return 0.0;
	}
	
	float depth = hud_vertical_depth(pixel, height, progress);
	return step(0.0, depth) * (1.0 - step(outline_width, depth));
}


vec4 hud_apply_caps(vec4 col, vec2 pixel, vec2 center, vec2 size) {
	vec2 offset = pixel + 0.5 - center;
	vec4 result = col;
	
	result.rgb = mix(result.rgb, metal_effect(col.rgb, pixel), hud_vertical_mask(pixel, size.y, metal_progress));
	
	float stripe = invisible_stripe_at(pixel.y);
	vec3 ghost = mix(invisible_tinted(result.rgb), vec3(1.0), stripe * invisible_stripe_brightness);
	vec4 ghosted = vec4(ghost, result.a * invisible_alpha(stripe));
	result = mix(result, ghosted, hud_radial_mask(offset, invisible_progress));
	
	result.rgb = mix(result.rgb, metal_outline.rgb, hud_vertical_edge(pixel, size.y, metal_progress) * metal_outline.a);
	result = mix(result, vec4(invisible_outline.rgb, col.a), hud_radial_edge(offset, invisible_progress) * invisible_outline.a);
	return result;
}
