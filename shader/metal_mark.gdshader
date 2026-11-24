shader_type canvas_item;
render_mode unshaded;

#include "res://shader/cap_effects/metal_mark.gdshaderinc"

uniform bool exempt = false;
uniform bool held = false;


void fragment() {
	COLOR.r = held_mark_red(COLOR.r, held);
	COLOR.b = metal_mark_blue(COLOR.b, exempt || held);
}
