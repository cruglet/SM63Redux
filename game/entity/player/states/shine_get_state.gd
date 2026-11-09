class_name ShineGetState
extends PlayerState

@export var animation: StringName = &"shine_get"

var kickout: bool = false
var _requested: bool = false


func _enter() -> void:
	_requested = false
	player.velocity = Vector2.ZERO
	player.lock_flipping = true
	sprite.play(animation)


func _exit() -> void:
	player.lock_flipping = false


func _tick(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	if sprite.playing or not kickout or _requested:
		return
	
	_requested = true
	var level: Level = Level.of(player)
	if level:
		level.request_kickout()


func _next() -> StringName:
	if sprite.playing or kickout:
		return &""
	if player.is_swimming():
		return &"SwimIdle"
	return &"Idle" if player.is_on_floor() else &"Fall"
