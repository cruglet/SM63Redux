class_name ShineGetState
extends PlayerState

signal celebration_started
signal celebration_ended

@export var animation: StringName = &"shine_get"
@export var fall_animation: StringName = &"fall_loop"
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2") var air_drag: float = 240.0
@export var hurt_box: HurtBox
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var invulnerable_after: float = 1.0
@export_group("Shine")
@export var follow_offset: Vector2 = Vector2(12.0, -30.0)
@export var follow_rate: float = 9.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var follow_bob: float = 2.0
@export var shine_root: Node2D
@export var shine_holder: Node2D
@export var visuals: CanvasItem
@export var face_animation: StringName = &"idle"
@export_group("Jingle")
@export var jingle_player: AudioStreamPlayer
@export var stay_jingle: AudioStream
@export var leave_jingle: AudioStream
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var stay_duration: float = 4.2
@export_group("Camera")
@export var celebration_zoom: float = 0.45
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var celebration_pan: Vector2 = Vector2(0.0, -24.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var celebration_zoom_time: float = 2.0
@export var celebration_zoom_curve: Curve
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var leave_duration: float = 3.3

var kickout: bool = false
var shine: Node2D
var _landed: bool = false
var _grounded: bool = false
var _elapsed: float = 0.0
var _requested: bool = false
var _air_time: float = 0.0
var _follow_position: Vector2 = Vector2.ZERO
var _settling_rig: SpriteRig2D


func _enter() -> void:
	_landed = false
	_elapsed = 0.0
	_requested = false
	_air_time = 0.0
	jingle_player.stop()
	player.lock_flipping = true
	hurt_box.disable()
	hurt_box.stop_blink()
	sprite.speed_scale = 1.0
	machine.animation_player.play(&"RESET")
	machine.animation_player.advance(0.0)
	shine_root.transform = GameObject.relative_transform(player, sprite)
	set_shine_front(true)
	_hold_shine()
	if not _try_land():
		sprite.play(fall_animation)


func _exit() -> void:
	celebration_ended.emit()
	_set_soft_paused(false)
	hurt_box.enable(invulnerable_after)
	player.lock_flipping = false
	sprite.speed_scale = 1.0
	controls.consume(&"jump")
	machine.animation_player.stop()
	if is_instance_valid(shine):
		shine.queue_free()
	shine = null


func _tick(delta: float) -> void:
	if not _landed and not _try_land():
		player.velocity.x = move_toward(player.velocity.x, 0.0, air_drag * delta)
		_follow_shine(delta)
		return
	
	player.velocity = Vector2.ZERO
	_elapsed += delta
	if not kickout or _requested or _elapsed < leave_duration:
		return
	
	_requested = true
	var level: Level = Level.of(player)
	if not (level and level.request_kickout()):
		kickout = false


func _next() -> StringName:
	if kickout or not _landed or _elapsed < stay_duration:
		return &""
	if player.is_swimming():
		return &"SwimIdle"
	return &"Idle" if _grounded else &"Fall"


func get_gravity_scale() -> float:
	return 0.0 if _landed else gravity_scale


func zoom_camera_out() -> void:
	var camera: LevelCamera = _get_camera()
	if kickout and camera:
		camera.tween_view(
				celebration_zoom,
				celebration_pan,
				celebration_zoom_time,
				celebration_zoom_curve,
		)


func set_shine_front(front: bool) -> void:
	var behind: int = int(shine_root.get_index() < visuals.get_index())
	player.move_child(shine_root, visuals.get_index() + int(front) - behind)


func settle_shine_face(duration: float) -> void:
	var rig: SpriteRig2D = shine as SpriteRig2D
	if rig == null or not rig.has_animation(face_animation):
		return
	
	var length: int = rig.get_clip_length(rig.current_animation)
	var remaining: int = posmod(-rig.current_frame, length)
	if remaining < length / 2:
		remaining += length
	_settling_rig = rig
	rig.speed_scale = remaining / (duration * rig.get_clip_fps(rig.current_animation))
	if not rig.frame_changed.is_connected(_on_settling_frame):
		rig.frame_changed.connect(_on_settling_frame)


func _hold_shine() -> void:
	if shine == null or shine.get_parent() == shine_holder:
		return
	
	shine_holder.global_position = shine.global_position
	shine_holder.scale = Vector2.ONE
	_follow_position = shine.global_position
	shine.reparent(shine_holder, false)
	shine.position = Vector2.ZERO
	shine.scale = Vector2(-1.0 if sprite.flip_h else 1.0, 1.0)


func _follow_shine(delta: float) -> void:
	if shine == null:
		return
	
	_air_time += delta
	var bob: Vector2 = Vector2(0.0, sin(_air_time * TAU) * follow_bob)
	var target: Vector2 = shine_root.global_transform * (follow_offset + bob)
	_follow_position = _follow_position.lerp(target, 1.0 - exp(-follow_rate * delta))
	shine_holder.global_position = _follow_position


func _on_settling_frame() -> void:
	if _settling_rig.current_frame != 0:
		return
	
	_settling_rig.frame_changed.disconnect(_on_settling_frame)
	_settling_rig.speed_scale = 1.0
	_settling_rig.play(face_animation)
	_settling_rig = null


func _try_land() -> bool:
	if not (player.has_landed() or player.is_swimming()):
		return false
	
	_landed = true
	_grounded = player.is_on_floor()
	player.velocity = Vector2.ZERO
	sprite.stop()
	sprite.current_animation = animation
	sprite.current_frame = 0
	machine.animation_player.play_with_capture(
			animation,
			-1.0,
			-1.0,
			1.0,
			false,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
	)
	if kickout:
		SFX.play(leave_jingle, jingle_player.bus)
	else:
		jingle_player.stream = stay_jingle
		jingle_player.play()
	celebration_started.emit()
	_set_soft_paused(true)
	return true


func _get_camera() -> LevelCamera:
	var level: Level = Level.of(player)
	return level.camera if level else null


func _set_soft_paused(paused: bool) -> void:
	var level: Level = Level.of(player)
	if level:
		level.set_soft_paused(paused)
