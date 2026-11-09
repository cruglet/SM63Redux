shader_type canvas_item;

#include "res://shader/cap_effects/common.gdshaderinc"
#include "res://shader/cap_effects/rainbow.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float half_width = 32.0;
uniform float fill_left : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float fill_right : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float shading : hint_range(0.0, 1.0, 0.01) = 0.6;

varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


void fragment() {
	vec4 col = COLOR;
	vec2 pixel = floor(local_position);
	float left = fill_left * half_width * 2.0;
	float ratio = (
		(pixel.x + half_width + 0.5 - left)
		/ (fill_right * half_width * 2.0 - left)
	);
	float inside = step(ratio, progress) * step(0.0001, progress);
	
	vec3 rainbow = rainbow_at(pixel) * mix(1.0, cap_luminance(col.rgb) * 1.6, shading);
	COLOR = vec4(mix(col.rgb, min(rainbow, vec3(1.0)), inside), col.a);
}
