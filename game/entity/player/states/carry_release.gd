extends PlayerState

@export var animation: StringName = &"kick"
@export var release_frame: int = 2
@export var walkable: bool = true

var _released: bool = false


func _enter() -> void:
	_released = false
	player.can_walk = walkable
	player.lock_flipping = true
	sprite.play(animation)


func _tick(_delta: float) -> void:
	if not _released and sprite.current_frame >= release_frame:
		_release()


func _exit() -> void:
	if not _released:
		_release()
	player.can_walk = true
	player.lock_flipping = false


func _next() -> StringName:
	if not player.is_on_floor():
		return &"Fall"
	if not sprite.playing:
		return &"Idle"
	return &""


func _release() -> void:
	_released = true
	player.carry.release_pending()
