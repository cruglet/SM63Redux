#ifndef CAP_EFFECTS_COMMON
#define CAP_EFFECTS_COMMON


float cap_luminance(vec3 rgb) {
	return dot(rgb, vec3(0.299, 0.587, 0.114));
}

#endif
