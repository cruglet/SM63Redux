class_name GroundPoundState
extends PlayerState

## Hitbox active for the whole ground pound.
@export var hitbox: HitBox
@export var fall: GroundPoundFallState
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cancel_cooldown: float = 0.4

var enabled: bool = true

var _armed: bool = false
var _ready_frame: int = 0


func _enter() -> void:
	_armed = false
	_sync_hitbox()


func _tick(_delta: float) -> void:
	_sync_hitbox()
	if _wants_cancel():
		controls.consume(&"jump")
		var cooldown_frames: int = ceili(cancel_cooldown * Engine.physics_ticks_per_second)
		_ready_frame = Engine.get_physics_frames() + cooldown_frames
		player.velocity.y = 0.0
		machine.change_state(&"Fall")


func _exit() -> void:
	_armed = false
	hitbox.disable()


func _next() -> StringName:
	return &"GroundPoundStart" if is_current() else &""


func wants_start() -> bool:
	return (
			not player.is_on_floor()
			and controls.is_held(&"ground_pound")
			and enabled
			and Engine.get_physics_frames() >= _ready_frame
			and not player.carry.is_holding()
	)


func is_impacting() -> bool:
	return player.velocity.y > 0.0 or fall.is_active() or machine.is_active(&"GroundPoundSlam")


func pierce() -> void:
	if not is_active():
		return
	
	if not fall.is_active():
		machine.change_state(&"GroundPoundFall")
	fall.pierce()


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
	if not fall.is_active() or player.is_swimming():
		return false
	return (
			controls.is_just_pressed(&"jump")
			or controls.is_just_pressed(&"glide_up")
			or controls.is_just_pressed(&"swim_up")
	)
