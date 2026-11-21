class_name PlayerCarry
extends Node

enum Release {
	KICK,
	UPKICK,
	THROW,
	DROP,
}

@export var player: Player
@export var hold_anchor: Node2D
@export var heavy_hold_anchor: Node2D
@export var reach: Rect2 = Rect2(-4.0, -28.0, 32.0, 40.0)
@export var touch_reach: Rect2 = Rect2(0.0, -20.0, 16.0, 28.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var touch_kick_speed: float = 20.0
@export var kick_animation: StringName = &"kick"
@export var kick_release_frame: int = 1
@export var throw_state: StringName = &"Throw"
@export var kick_sound: AudioStream
@export_range(0.0, 1.0, 0.05) var upkick_momentum: float = 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var release_grace: float = 0.2
@export_group("States")
@export var grab_states: Array[StringName] = [
	&"Idle",
	&"Walk",
	&"Crouch",
	&"Fall",
	&"Jump",
	&"IdleJump",
	&"SwimIdle",
	&"Swim",
	&"SwimWalk",
]
@export var drop_states: Array[StringName] = [&"Strike", &"DeathHit", &"DeathFall", &"ShineGet"]
@export var redirected_states: Dictionary[StringName, StringName] = {
	&"Dive": &"",
	&"Spin": &"",
	&"Glide": &"",
	&"RolloutF": &"",
	&"SwimSpin": &"",
	&"SwimStrike": &"",
	&"Sleep": &"",
	&"Crouch": &"",
	&"Floorslide": &"",
	&"Backflip": &"BaseJump",
	&"BackflipUp": &"BaseJump",
}

var held: Carryable

var _pending: Release = Release.KICK
var _released: Entity
var _grace: float = 0.0
var _kick_time: float = -1.0
var _underlying: StringName = &""


func tick(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)
	_tick_kick(delta)
	var free: bool = not held and not player.interactions_locked
	var target: Carryable = find_target() if free and can_grab() else null
	for node: Node in get_tree().get_nodes_in_group(Carryable.GROUP):
		(node as Carryable).highlighted = node == target
	if held:
		_tick_held()
	elif target and player.controls.is_held(&"use_fludd"):
		grab(target)
	elif free:
		_try_touch_kick()


func is_holding() -> bool:
	return held != null


func is_kicking() -> bool:
	return _kick_time >= 0.0


func ignores(node: Node) -> bool:
	if held and node == held.entity:
		return true
	return _grace > 0.0 and is_instance_valid(_released) and node == _released


func can_grab() -> bool:
	return (
			player.fludd.equipped_nozzle == PlayerFludd.Nozzle.NONE
			and grab_states.has(player.machine.get_state_name())
	)


func find_target() -> Carryable:
	var best: Carryable
	var best_distance: float = INF
	for carryable: Carryable in _get_carryables():
		var offset: Vector2 = carryable.entity.global_position - player.global_position
		offset.x *= player.get_facing()
		if reach.has_point(offset) and offset.length_squared() < best_distance:
			best = carryable
			best_distance = offset.length_squared()
	
	return best


func grab(carryable: Carryable) -> void:
	held = carryable
	held.released.connect(_on_released, CONNECT_ONE_SHOT)
	held.pick_up(heavy_hold_anchor if held.heavy else hold_anchor, player)
	player.sprite.set_variant(&"hold", &"heavy" if held.heavy else &"light")


func release(kind: Release) -> void:
	if not held:
		return
	
	var facing: Vector2 = Vector2(player.get_facing(), 1.0)
	var from: Vector2 = player.global_position
	_ignore(held.entity)
	
	match kind:
		Release.KICK:
			_play_kick()
			held.throw(held.kick_velocity * facing, from)
		Release.UPKICK:
			_play_kick()
			var carried: Vector2 = Vector2(player.velocity.x * upkick_momentum, 0.0)
			held.throw(held.upkick_velocity * facing + carried, from)
		Release.THROW:
			held.throw(held.throw_velocity * facing, from)
		Release.DROP:
			held.drop(player.velocity + held.drop_velocity * facing, from)


func release_pending() -> void:
	release(_pending)


func redirect(from: State, to: StringName) -> StringName:
	if not held or not from:
		return to
	if to == &"BaseJump" and player.controls.is_held(&"crouch"):
		return from.name
	if not redirected_states.has(to):
		return to
	
	var target: StringName = redirected_states[to]
	return from.name if target.is_empty() else target


func _tick_held() -> void:
	var state: StringName = player.machine.get_state_name()
	if drop_states.has(state):
		release(Release.DROP)
		return
	
	held.follow()
	if is_kicking() or state == throw_state or player.controls.is_held(&"use_fludd"):
		return
	
	_pending = _choose_release()
	if _pending == Release.KICK or _pending == Release.UPKICK:
		_start_kick()
	elif _pending == Release.THROW and player.is_on_floor() and not player.is_swimming():
		player.machine.change_state(throw_state)
	else:
		release_pending()


func _choose_release() -> Release:
	var down: bool = player.controls.is_held(&"crouch")
	var up: bool = (
			minf(player.controls.glide, player.controls.swim) < -PlayerInput.AXIS_THRESHOLD
			or down and player.controls.is_held(&"jump")
	)
	if down and not up:
		return Release.DROP
	if held.heavy:
		return Release.THROW
	if up and not (down and not player.is_on_floor()):
		return Release.UPKICK
	return Release.KICK


func _try_touch_kick() -> void:
	for carryable: Carryable in _get_carryables():
		if not carryable.kick_on_touch or ignores(carryable.entity):
			continue
		
		var offset: Vector2 = carryable.entity.global_position - player.global_position
		var direction: float = signf(offset.x)
		offset.x = absf(offset.x)
		if not touch_reach.has_point(offset) or player.velocity.x * direction < touch_kick_speed:
			continue
		
		_ignore(carryable.entity)
		_play_kick()
		carryable.kick(carryable.kick_velocity * Vector2(direction, 1.0), player)
		_start_kick()
		return


func _start_kick() -> void:
	_kick_time = 0.0
	_underlying = player.sprite.current_animation
	player.sprite.play_at_frame(kick_animation, 0)


func _tick_kick(delta: float) -> void:
	if not is_kicking():
		return
	if drop_states.has(player.machine.get_state_name()):
		_kick_time = -1.0
		return
	
	var sprite: SpriteRig2D = player.sprite
	if sprite.current_animation != kick_animation:
		_underlying = sprite.current_animation
	var frame: int = int(_kick_time * sprite.get_clip_fps(kick_animation))
	if held and frame >= kick_release_frame:
		release_pending()
	if frame >= sprite.get_clip_length(kick_animation):
		_kick_time = -1.0
		sprite.play(_underlying)
		return
	
	if sprite.current_animation != kick_animation or sprite.current_frame != frame:
		sprite.play_at_frame(kick_animation, frame)
	_kick_time += delta


func _get_carryables() -> Array[Carryable]:
	var result: Array[Carryable] = []
	for node: Node in get_tree().get_nodes_in_group(Carryable.GROUP):
		var carryable: Carryable = node as Carryable
		if carryable and carryable.can_carry():
			result.append(carryable)
	return result


func _ignore(entity: Entity) -> void:
	_released = entity
	_grace = release_grace


func _play_kick() -> void:
	if kick_sound:
		SFX.play(kick_sound, &"Player")


func _on_released() -> void:
	held = null
	player.sprite.set_variant(&"hold", &"")
