shader_type canvas_item;

#include "res://shader/cap_effects/combined.gdshaderinc"

uniform sampler2D screen_texture :
	hint_screen_texture, repeat_disable, filter_nearest;
instance uniform float metal_amount = 0.0;
instance uniform float metal_facing = 1.0;
instance uniform float invisible_amount = 0.0;

varying vec2 local_position;
varying float pixel_scale;


void vertex() {
	local_position = VERTEX;
	pixel_scale = length(CANVAS_MATRIX[0].xy);
}


void fragment() {
	vec4 source = textureLod(screen_texture, SCREEN_UV, 0.0);
	bool exempt = metal_mark_is_exempt(source);
	bool held = held_mark_is_set(source);
	if (source.a > 0.0001) {
		source.rgb /= source.a;
	}
	
	if (!held && (metal_amount > 0.0 || invisible_amount > 0.0)) {
		source = cap_effect(
			CAP_SAMPLES(screen_texture, SCREEN_UV, SCREEN_PIXEL_SIZE * pixel_scale, metal_facing),
			source,
			local_position,
			metal_amount,
			metal_facing,
			invisible_amount,
			exempt
		);
	}
	COLOR *= source;
}
