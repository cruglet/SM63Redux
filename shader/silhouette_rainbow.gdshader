shader_type canvas_item;
render_mode unshaded;

#include "res://shader/cap_effects/rainbow.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int thickness : hint_range(1, 8) = 1;
uniform float brightness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float fill_alpha : hint_range(0.0, 1.0, 0.01) = 0.0;

varying vec2 local_position;
varying float modulate_alpha;


void vertex() {
	local_position = VERTEX;
	modulate_alpha = COLOR.a;
}


void fragment() {
	vec2 texel = vec2(
		length(dFdx(SCREEN_UV)) / max(length(dFdx(local_position)), 0.0001),
		length(dFdy(SCREEN_UV)) / max(length(dFdy(local_position)), 0.0001)
	);
	float alpha = texture(screen_texture, SCREEN_UV).a;
	float edge = 0.0;
	
	for (int x = -thickness; x <= thickness; x++) {
		for (int y = -thickness; y <= thickness; y++) {
			edge = max(
				edge,
				alpha - texture(
					screen_texture,
					SCREEN_UV + vec2(float(x), float(y)) * texel
				).a
			);
		}
	}
	
	COLOR = vec4(
		rainbow_at(local_position) * brightness,
		max(step(0.5, edge), step(0.5, alpha) * fill_alpha) * modulate_alpha
	);
}
