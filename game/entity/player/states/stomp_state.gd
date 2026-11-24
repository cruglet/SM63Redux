class_name StompState
extends PlayerState

## Time gravity is suspended before bouncing.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration: float = 0.15
## Upward speed set once the stomp ends.
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var bounce_speed: float = 272.5
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var held_bounce_speed: float = 412.5
@export_group("Squish")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var squish_bounce_speed: float = 200.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var held_squish_bounce_speed: float = 412.5
@export_group("Drag")
## Horizontal deceleration while stomping.
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2") var drag: float = 500.0
## Horizontal speed the stomp drag stops at.
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var min_speed: float = 45.0


func _enter() -> void:
	player.velocity.y = minf(player.velocity.y, 0.0)


func _tick(delta: float) -> void:
	var speed: float = absf(player.velocity.x)
	if speed > min_speed:
		player.velocity.x = maxf(speed - drag * delta, min_speed) * signf(player.velocity.x)
	
	if time >= duration and time - delta < duration:
		var held: bool = controls.is_held(&"jump")
		player.velocity.y = -player.get_jump_speed(held_bounce_speed if held else bounce_speed)


func _next() -> StringName:
	if player.velocity.y < 0.0:
		return &"Fall"
	if player.is_on_floor():
		return &"Idle"
	return &"Fall" if time >= duration else &""


func get_gravity_scale() -> float:
	return 0.0 if time < duration else gravity_scale


func bounce_off_squish() -> void:
	var held: bool = controls.is_held(&"jump")
	if held and machine.is_active(&"Airborne") and not machine.is_active(&"Dive"):
		machine.change_state(&"IdleJump")
	var speed: float = held_squish_bounce_speed if held else squish_bounce_speed
	player.velocity.y = -player.get_jump_speed(speed)
