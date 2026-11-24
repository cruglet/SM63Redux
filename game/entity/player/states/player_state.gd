class_name PlayerState
extends State

@export_group("Physics")
@export var gravity_scale: float = 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var max_fall_speed: float = 0.0
@export var air_control: PlayerAirControl
@export var collision_shape: CollisionShape2D

var player: Player
var controls: PlayerInput


func _bind() -> void:
	player = entity as Player
	controls = player.controls


func get_gravity_scale() -> float:
	return gravity_scale


func overrides_vertical() -> bool:
	return false


func is_striking() -> bool:
	return false


func drive(
		input: float,
		max_speed: float,
		acceleration: float,
		turn_acceleration: float,
		turn_threshold: float,
		drag_rate: float,
		delta: float,
) -> void:
	var direction: float = signf(input)
	var cap: float = max_speed * absf(input)
	var speed: float = player.velocity.x * direction
	if speed >= cap:
		speed = maxf(Motion.drift(speed, 0.0, drag_rate, delta), cap)
	else:
		var turning: bool = speed < -turn_threshold
		speed = minf(
				Motion.drift(
						speed,
						turn_acceleration if turning else acceleration,
						drag_rate,
						delta,
				),
				cap,
		)
	
	player.velocity.x = speed * direction


func brake(deceleration: float, drag_rate: float, delta: float) -> void:
	var speed: float = maxf(
			Motion.drift(absf(player.velocity.x), -deceleration, drag_rate, delta),
			0.0,
	)
	player.velocity.x = speed * signf(player.velocity.x)
