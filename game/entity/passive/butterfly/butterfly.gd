class_name Butterfly
extends Prop

enum Flight {
	WANDER,
	LANDING,
	PERCHED,
	LEAVING,
}

const GROUP: StringName = &"butterflies"

@export var sprite: SpriteRig2D
@export var path_follow_2d: PathFollow2D
@export var perched_flap_speed: float = 0.3
@export var perched_z_index: int = 20
@export_group("Flight")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var fly_speed: float = 35.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var steer_halflife: float = 0.3
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var arrive_radius: float = 28.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var hover_height: float = 24.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var flutter: float = 26.0
@export var flutter_rate: float = 6.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var settle_distance: float = 0.75

var speed: float = randf_range(15.0, 25.0)
var _previous_x: float = 0.0
var _flight: Flight = Flight.WANDER
var _perch: Node2D
var _home: Vector2
var _home_z: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _flight_time: float = 0.0


func _process(delta: float) -> void:
	match _flight:
		Flight.WANDER:
			_wander(delta)
		Flight.LANDING:
			if not is_instance_valid(_perch):
				leave()
			elif _fly_to(_perch.global_position, delta):
				_flight = Flight.PERCHED
				sprite.speed_scale = perched_flap_speed
				sprite.z_index = perched_z_index
		Flight.PERCHED:
			if not is_instance_valid(_perch):
				leave()
			else:
				sprite.global_position = _perch.global_position
		Flight.LEAVING:
			if _fly_to(path_follow_2d.to_global(_home), delta):
				_flight = Flight.WANDER
				sprite.position = _home
				_previous_x = path_follow_2d.position.x


func _on_init() -> void:
	add_to_group(GROUP)
	_home = sprite.position
	_home_z = sprite.z_index
	sprite.play(&"flap")
	path_follow_2d.progress = randf_range(0.0, 300.0)


func can_perch() -> bool:
	return _flight == Flight.WANDER


func get_flight_position() -> Vector2:
	return sprite.global_position


func perch(target: Node2D) -> void:
	_perch = target
	_flight_time = 0.0
	_flight = Flight.LANDING


func leave() -> void:
	if _flight == Flight.WANDER or _flight == Flight.LEAVING:
		return
	
	_perch = null
	_flight_time = 0.0
	_flight = Flight.LEAVING
	sprite.speed_scale = 1.0
	sprite.z_index = _home_z


func _wander(delta: float) -> void:
	var before: Vector2 = sprite.global_position
	path_follow_2d.progress += delta * speed
	if delta > 0.0:
		_velocity = (sprite.global_position - before) / delta
	
	var moved: float = path_follow_2d.position.x - _previous_x
	if not is_zero_approx(moved):
		sprite.flip_h = moved < 0.0
	
	_previous_x = path_follow_2d.position.x


func _fly_to(target: Vector2, delta: float) -> bool:
	_flight_time += delta
	var offset: Vector2 = target - sprite.global_position
	var distance: float = offset.length()
	if distance <= settle_distance:
		sprite.global_position = target
		_velocity = Vector2.ZERO
		return true
	
	var approach: float = clampf(distance / arrive_radius, 0.0, 1.0)
	var aim: Vector2 = target + Vector2.UP * hover_height * approach
	var heading: Vector2 = sprite.global_position.direction_to(aim)
	var bob: Vector2 = Vector2(
			sin(_flight_time * flutter_rate),
			0.5 * cos(_flight_time * flutter_rate * 1.3),
	)
	var desired: Vector2 = heading * fly_speed * approach + bob * flutter * approach
	_velocity = _velocity.lerp(desired, 1.0 - pow(2.0, -delta / steer_halflife))
	sprite.global_position += _velocity * delta
	if absf(_velocity.x) > 1.0:
		sprite.flip_h = _velocity.x < 0.0
	return false
