#ifndef CAP_EFFECTS_RAINBOW
#define CAP_EFFECTS_RAINBOW

group_uniforms rainbow;
uniform float rainbow_saturation : hint_range(0.0, 1.0, 0.01) = 0.85;
uniform float rainbow_cycle_speed = 1.2;
uniform float rainbow_spread = 0.03;
group_uniforms rainbow.border;
uniform float rainbow_border_lightness : hint_range(0.0, 1.0, 0.01) = 0.0;
group_uniforms;


vec3 rainbow_at(vec2 position) {
	vec2 pixel = floor(position);
	float hue = fract(TIME * rainbow_cycle_speed - (pixel.x + pixel.y) * rainbow_spread);
	vec3 channels = clamp(
		abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
		0.0,
		1.0
	);
	return mix(vec3(1.0), channels, rainbow_saturation);
}


vec3 rainbow_effect(vec3 rgb, vec2 position) {
	return rainbow_at(position) * max(max(rgb.r, rgb.g), rgb.b);
}


vec3 rainbow_border(vec2 position) {
	return mix(rainbow_at(position), vec3(1.0), rainbow_border_lightness);
}

#endif
