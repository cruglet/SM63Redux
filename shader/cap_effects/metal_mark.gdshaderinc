#ifndef CAP_EFFECTS_METAL_MARK
#define CAP_EFFECTS_METAL_MARK


float metal_mark_blue(float blue, bool exempt) {
	return (floor(blue * 127.5) * 2.0 + (exempt ? 1.0 : 0.0)) / 255.0;
}


bool metal_mark_is_exempt(vec4 color) {
	return color.a > 0.99 && mod(round(color.b * 255.0), 2.0) > 0.5;
}


float held_mark_red(float red, bool held) {
	return (floor(red * 127.5) * 2.0 + (held ? 1.0 : 0.0)) / 255.0;
}


bool held_mark_is_set(vec4 color) {
	return color.a > 0.99 && mod(round(color.r * 255.0), 2.0) > 0.5;
}

#endif
