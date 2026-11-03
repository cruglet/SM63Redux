class_name ChaseState
extends State


const ACCELERATION_RATIO: float = 0.125

@export var chase_speed: float = 80.0
@export var snap_to_speed_on_enter: bool = false
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var dead_zone: float = 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var drop_height: float = 16.0
@export var floor_check_l: RayCast2D
@export var floor_check_r: RayCast2D

var _detector: PlayerDetectorComponent


func _bind() -> void:
	_detector = entity.get_component(PlayerDetectorComponent) as PlayerDetectorComponent


func _enter() -> void:
	var heading: float = _get_heading()
	if snap_to_speed_on_enter and not _is_blocked(heading):
		entity.velocity.x = heading * chase_speed


func _tick(_delta: float) -> void:
	var heading: float = _get_heading()
	if not is_zero_approx(heading):
		sprite.flip_h = heading < 0.0
	
	var step: float = chase_speed * ACCELERATION_RATIO
	if is_zero_approx(heading) or _is_blocked(heading):
		entity.velocity.x = move_toward(entity.velocity.x, 0.0, step)
	else:
		entity.velocity.x = clampf(entity.velocity.x + heading * step, -chase_speed, chase_speed)


func _get_heading() -> float:
	if not _detector or not _detector.has_target():
		return 0.0
	
	var offset: float = _detector.target.global_position.x - entity.global_position.x
	return 0.0 if absf(offset) <= dead_zone else signf(offset)


func _is_blocked(heading: float) -> bool:
	var target_below: bool = (
			_detector != null
			and _detector.has_target()
			and _detector.target.global_position.y > entity.global_position.y + drop_height
	)
	if target_below and not entity.is_on_wall():
		return false
	
	return entity.is_path_blocked(heading, floor_check_l, floor_check_r)
