#ifndef CAP_EFFECTS_INVISIBLE
#define CAP_EFFECTS_INVISIBLE

#include "res://shader/cap_effects/common.gdshaderinc"

group_uniforms invisible;
uniform vec4 invisible_tint : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float invisible_tint_strength : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float invisible_body_alpha : hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float invisible_stripe_alpha : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float invisible_stripe_brightness : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float invisible_stripe_spacing : hint_range(2.0, 16.0, 1.0) = 4.0;
uniform float invisible_stripe_speed = 12.0;
group_uniforms;


float invisible_stripe_at(float y) {
	float row = floor(y) + floor(TIME * invisible_stripe_speed);
	return step(invisible_stripe_spacing - 1.0, mod(row, invisible_stripe_spacing));
}


vec3 invisible_tinted(vec3 rgb) {
	vec3 tinted = invisible_tint.rgb * (0.5 + cap_luminance(rgb));
	return mix(rgb, tinted, invisible_tint_strength);
}


float invisible_alpha(float stripe) {
	return invisible_body_alpha + stripe * invisible_stripe_alpha;
}

#endif
