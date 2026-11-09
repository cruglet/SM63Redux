extends PlayerState

@export var start_animation: StringName = &"sleep_start"
@export var loop_animation: StringName = &"sleep_loop"
@export var wake_animation: StringName = &"sleep_end"
@export var wake_speed: float = 2.5
@export_group("Butterfly")
@export var butterfly_perch: Marker2D
@export_range(0.0, 1.0, 0.01) var butterfly_chance: float = 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var butterfly_roll_interval: float = 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var butterfly_range: float = 192.0

var _waking: bool = false
var _roll_time: float = 0.0
var _butterfly: Butterfly


func _enter() -> void:
	_waking = false
	_roll_time = 0.0
	player.lock_flipping = true
	sprite.speed_scale = 1.0
	sprite.play(start_animation)


func _exit() -> void:
	player.lock_flipping = false
	sprite.speed_scale = 1.0
	_release_butterfly()


func _tick(delta: float) -> void:
	player.velocity.x = 0.0
	if _waking or _wants_jump():
		return
	
	if controls.has_input():
		_waking = true
		sprite.speed_scale = wake_speed
		sprite.play(wake_animation)
		_release_butterfly()
	elif not sprite.playing:
		sprite.play(loop_animation)
	
	if sprite.current_animation == loop_animation:
		_tick_butterfly(delta)


func _next() -> StringName:
	if not player.is_on_floor():
		return &"Fall"
	if _wants_jump():
		return &"BaseJump"
	if _waking and not sprite.playing:
		return &"Idle"
	return &""


func _wants_jump() -> bool:
	return player.can_jump and controls.is_held(&"jump")


func _tick_butterfly(delta: float) -> void:
	if not butterfly_perch:
		return
	if is_instance_valid(_butterfly):
		return
	
	_roll_time += delta
	if _roll_time < butterfly_roll_interval:
		return
	
	_roll_time = 0.0
	if randf() >= butterfly_chance:
		return
	
	_butterfly = _find_butterfly()
	if _butterfly:
		_butterfly.perch(butterfly_perch)


func _find_butterfly() -> Butterfly:
	var nearest: Butterfly = null
	var best: float = butterfly_range
	for node: Node in player.get_tree().get_nodes_in_group(Butterfly.GROUP):
		var butterfly: Butterfly = node as Butterfly
		if not butterfly or not butterfly.can_perch() or not butterfly.can_process():
			continue
		
		var distance: float = \
				butterfly.get_flight_position().distance_to(butterfly_perch.global_position)
		if distance <= best:
			best = distance
			nearest = butterfly
	
	return nearest


func _release_butterfly() -> void:
	if is_instance_valid(_butterfly):
		_butterfly.leave()
	_butterfly = null
