@abstract class_name CapMode
extends Mode

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration: float = 0.0
@export var music: AudioStream
@export var traits: Array[StringName] = []
@export var effect_target: CanvasItem
@export var effect_parameter: StringName = &""
@export var effect_exempt: Array[CanvasItem] = []
@export var exempt_material: Material
@export_group("Blink")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var blink_time: float = 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s")
var blink_interval_start: float = 0.25
@export_custom(PROPERTY_HINT_NONE, "suffix:s")
var blink_interval_end: float = 0.05

var player: Player

var _blink_phase: float = 0.0
var _effect_shown: bool = false


func _bind() -> void:
	player = host as Player


func _enter() -> void:
	_blink_phase = 0.0
	_set_effect_shown(true)


func _tick(delta: float) -> void:
	var remaining: float = duration - time
	if is_timed() and blink_time > 0.0 and remaining <= blink_time:
		_blink_phase += delta / lerpf(
				blink_interval_start,
				blink_interval_end,
				1.0 - remaining / blink_time,
		)
	
	_set_effect_shown(int(_blink_phase) % 2 == 0)
	if is_timed() and time >= duration:
		end()


func _exit() -> void:
	_set_effect_shown(false)


func get_remaining_ratio() -> float:
	return clampf(1.0 - time / duration, 0.0, 1.0) if is_timed() else 1.0


func is_timed() -> bool:
	return duration > 0.0 and not permanent


func get_scale(attribute: StringName) -> float:
	var value: Variant = get(attribute)
	return value if value is float else 1.0


func get_animation_override(animation: StringName) -> StringName:
	return animation


func get_footstep_terrain() -> StringName:
	return &""


func get_water_fall_speed(_pounding: bool) -> float:
	return 0.0


func redirect_state(_from: StringName, to: StringName) -> StringName:
	return to


func set_flapping(_flapping: bool) -> void:
	pass


func _show_effect(shown: bool) -> void:
	for item: CanvasItem in effect_exempt:
		item.use_parent_material = not shown
		item.material = exempt_material if shown else null
	if effect_target and not effect_parameter.is_empty():
		effect_target.set_instance_shader_parameter(effect_parameter, 1.0 if shown else 0.0)


func _set_effect_shown(shown: bool) -> void:
	if shown == _effect_shown:
		return
	
	_effect_shown = shown
	_show_effect(shown)
