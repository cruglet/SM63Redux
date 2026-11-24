extends PlayerState

## Hitbox active for the whole ground pound.
@export var hitbox: HitBox
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cancel_cooldown: float = 0.4

var _armed: bool = false


func _enter() -> void:
	_armed = false
	_sync_hitbox()


func _tick(_delta: float) -> void:
	_sync_hitbox()
	if _wants_cancel():
		controls.consume(&"jump")
		player.pound_cooldown = cancel_cooldown
		player.velocity.y = 0.0
		machine.change_state(&"Fall")


func _exit() -> void:
	_armed = false
	hitbox.disable()


func _next() -> StringName:
	return &"GroundPoundStart" if is_current() else &""


func _sync_hitbox() -> void:
	var armed: bool = not player.is_swimming()
	if armed == _armed:
		return
	
	_armed = armed
	if armed:
		hitbox.enable()
	else:
		hitbox.disable()


func _wants_cancel() -> bool:
	if not machine.is_active(&"GroundPoundFall") or player.is_swimming():
		return false
	return (
			controls.is_just_pressed(&"jump")
			or controls.is_just_pressed(&"glide_up")
			or controls.is_just_pressed(&"swim_up")
	)
