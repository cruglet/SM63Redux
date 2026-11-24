class_name PlayerInput
extends RefCounted

const ACTIONS: Array[StringName] = [
	&"jump",
	&"crouch",
	&"dive",
	&"ground_pound",
	&"spin",
	&"use_fludd",
	&"switch_nozzle",
	&"glide_up",
	&"swim_up",
]
const AXIS_THRESHOLD: float = 0.2

var move: float = 0.0
var swim: float = 0.0
var glide: float = 0.0
var quiet_time: float = 0.0

var _press_ages: Dictionary[StringName, float] = {}


func poll(delta: float) -> void:
	move = Input.get_axis(&"move_left", &"move_right")
	swim = Input.get_axis(&"swim_up", &"swim_down")
	glide = Input.get_axis(&"glide_up", &"glide_down")
	for action: StringName in ACTIONS:
		if Input.is_action_just_pressed(action):
			_press_ages[action] = 0.0
		elif _press_ages.has(action):
			_press_ages[action] = _press_ages[action] + delta
	
	quiet_time = 0.0 if has_input() else quiet_time + delta


func has_input() -> bool:
	if maxf(absf(move), maxf(absf(swim), absf(glide))) > AXIS_THRESHOLD:
		return true
	
	for action: StringName in ACTIONS:
		if is_held(action):
			return true
	
	return false


func is_held(action: StringName) -> bool:
	return Input.is_action_pressed(action)


func is_just_pressed(action: StringName) -> bool:
	return _press_ages.get(action, INF) == 0.0


func take_buffered(action: StringName, window: float) -> bool:
	if not was_pressed_within(action, window):
		return false
	
	consume(action)
	return true


func was_pressed_within(action: StringName, window: float) -> bool:
	return _press_ages.get(action, INF) <= window


func consume(action: StringName) -> void:
	_press_ages.erase(action)
