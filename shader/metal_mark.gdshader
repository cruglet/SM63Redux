shader_type canvas_item;

#include "res://shader/cap_effects/metal_mark.gdshaderinc"

uniform bool exempt = false;


void fragment() {
	COLOR.b = metal_mark_blue(COLOR.b, exempt);
}
