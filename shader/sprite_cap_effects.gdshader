shader_type canvas_item;

#include "res://shader/cap_effects/combined.gdshaderinc"
#include "res://shader/cap_effects/rainbow.gdshaderinc"

uniform float metal_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float metal_facing = 1.0;
uniform float invisible_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float rainbow_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform bool rainbow_border_enabled = false;

varying vec2 local_position;
varying vec4 modulate_color;


void vertex() {
	local_position = VERTEX;
	modulate_color = COLOR;
}


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (metal_amount > 0.0 || invisible_amount > 0.0) {
		color = cap_effect(
			CAP_SAMPLES(TEXTURE, UV, TEXTURE_PIXEL_SIZE, metal_facing),
			color,
			local_position,
			metal_amount,
			metal_facing,
			invisible_amount,
			false
		);
	}
	if (rainbow_amount > 0.0) {
		vec3 rainbow = rainbow_effect(color.rgb, local_position);
		if (rainbow_border_enabled) {
			float neighbours = min(
				min(
					texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a,
					texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a
				),
				min(
					texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a,
					texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a
				)
			);
			float border = step(0.5, color.a) * (1.0 - step(0.5, neighbours));
			rainbow = mix(rainbow, rainbow_border(local_position), border);
		}
		color.rgb = mix(color.rgb, rainbow, rainbow_amount);
	}
	COLOR = modulate_color * color;
}
