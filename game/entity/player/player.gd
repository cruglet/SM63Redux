class_name Player
extends Entity

const TERRAIN_LAYER_FIRST: int = 25
const TOPLINE_TOLERANCE: float = 4.0

@export_group("Physics")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2") var gravity: float = 900.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s")
var floor_friction_halflife: float = 0.1482
@export_group("Terrain")
@export var floor_raycast: RayCast2D
@export var terrains: Array[StringName] = [
	&"grass",
	&"snow",
	&"cloud",
	&"ice",
	&"metal",
]
@export_group("Nodes")
@export var fludd: PlayerFludd
@export var carry: PlayerCarry
@export var water: PlayerWater
@export var caps: MultiModeMachine
@export var silhouette_targets: Array[Sprite2D]
@export var base_collision: CollisionShape2D
@export_group("States")
@export var jumps: BaseJumpState
@export var ground_pound: GroundPoundState
@export var stomp: StompState
@export var shine_get: ShineGetState

var controls: PlayerInput = PlayerInput.new()
var move_input: float = 0.0
var lock_flipping: bool = false
var can_jump: bool = true
var can_walk: bool = true
var can_dive: bool = true
var ground_speed_override: float = 0.0
var air_speed_override: float = 0.0
var gravity_modifiers: ModifierStack = ModifierStack.new()
var friction_modifiers: ModifierStack = ModifierStack.new()
var debug_forces: Dictionary[StringName, Vector2] = {}

var _collision: CollisionShape2D


func _physics_process(delta: float) -> void:
	controls.poll(delta)
	move_input = controls.move
	if fludd.is_turbo_active() and is_zero_approx(move_input):
		move_input = float(get_facing())
	
	caps.tick(delta, not shine_get.is_active())
	gravity_modifiers.tick(delta)
	friction_modifiers.tick(delta)
	machine.tick(delta)
	_update_collision()
	if not lock_flipping and not is_zero_approx(move_input):
		sprite.flip_h = move_input < 0.0
	
	fludd.tick(delta)
	if not _velocity_lock:
		_integrate(delta)
	carry.tick(delta)


func get_attribute_scale(attribute: StringName) -> float:
	var result: float = 1.0
	for cap: CapMode in get_caps():
		result *= cap.get_scale(attribute)
	
	return result


func is_intangible() -> bool:
	return has_cap(&"intangible")


func is_harmless() -> bool:
	return has_cap(&"harmless") and not has_cap(&"lethal")


func ignores_hit(hitbox: HitBox) -> bool:
	return carry.ignores(hitbox.owner) or carry.would_catch(hitbox.owner)


func bounce_off_squish() -> void:
	stomp.bounce_off_squish()


func redirect_state(from: State, to: StringName) -> StringName:
	if not from:
		return to
	
	to = carry.redirect(from, to)
	for cap: CapMode in get_caps():
		var redirected: StringName = cap.redirect_state(from.name, to)
		if redirected != to:
			return redirected
	
	return to


func get_terrain() -> StringName:
	if not floor_raycast.is_colliding():
		return &""
	
	var collider: CollisionObject2D = floor_raycast.get_collider() as CollisionObject2D
	if not collider:
		return &""
	
	var game_object: GameObject = GameObject.of(collider)
	if (
			game_object
			and game_object.shape is PolygonShape
			and not (game_object.shape as PolygonShape).is_on_topline(
					floor_raycast.get_collision_point(),
					TOPLINE_TOLERANCE,
			)
	):
		return &""
	
	for i: int in terrains.size():
		if collider.get_collision_layer_value(TERRAIN_LAYER_FIRST + i):
			return terrains[i]
	
	return StringName(collider.get_meta(&"terrain", ""))


func get_sound_terrain() -> StringName:
	for cap: CapMode in get_caps():
		if not cap.get_footstep_terrain().is_empty():
			return cap.get_footstep_terrain()
	
	return get_terrain()


func get_debug_text() -> String:
	var text: String = "State: %s\nAnimation: %s\nVelocity: %s\nQuiet: %.1fs\n" % [
		machine.get_state(),
		sprite.current_animation,
		velocity,
		controls.quiet_time,
	]
	if not is_equal_approx(Singleton.debug_time.get_scale(), 1.0):
		text += "Time: %sx\n" % Singleton.debug_time.get_scale()
	return text


func is_detectable() -> bool:
	return not has_cap(&"undetectable")


func celebrate_shine(kickout: bool, shine: Node2D = null) -> void:
	shine_get.kickout = kickout
	shine_get.shine = shine
	machine.change_state(&"ShineGet")


func get_caps() -> Array[CapMode]:
	var result: Array[CapMode] = []
	result.assign(caps.get_running_modes())
	return result


func has_cap(cap_trait: StringName) -> bool:
	return get_caps().any(func(cap: CapMode) -> bool: return cap.traits.has(cap_trait))


func get_cap_animation(animation: StringName) -> StringName:
	for cap: CapMode in get_caps():
		animation = cap.get_animation_override(animation)
	
	return animation


func set_wings_flapping(flapping: bool) -> void:
	for cap: CapMode in get_caps():
		cap.set_flapping(flapping)


func can_glide() -> bool:
	return not is_in_water() and has_cap(&"glide")


func is_swimming() -> bool:
	return is_in_water() and not has_cap(&"ignores_water")


func is_dive_striking() -> bool:
	return machine.get_active_states().any(
			func(state: State) -> bool: return (state as PlayerState).is_striking()
	)


func get_slope_angle(fallback: float) -> float:
	if not floor_raycast.is_colliding():
		return fallback
	
	return floor_raycast.get_collision_normal().angle() + PI / 2.0


func get_gravity_strength() -> float:
	var gravity_scale: float = gravity_modifiers.product()
	for state: State in machine.get_active_states():
		gravity_scale *= (state as PlayerState).get_gravity_scale()
	
	if is_in_water():
		gravity_scale *= (
				get_attribute_scale(&"water_gravity_scale")
				if has_cap(&"ignores_water")
				else water.gravity_scale
		)
	
	return gravity * gravity_scale


func get_fall_speed_cap() -> float:
	var cap: float = INF
	for state: State in machine.get_active_states():
		var limit: float = (state as PlayerState).max_fall_speed
		if limit > 0.0:
			cap = minf(cap, limit)
	
	if is_in_water():
		var pounding: bool = ground_pound.is_active()
		for cap_mode: CapMode in get_caps():
			var water_limit: float = cap_mode.get_water_fall_speed(pounding)
			if water_limit > 0.0:
				cap = minf(cap, water_limit)
	
	return cap


func get_floor_drag_rate() -> float:
	return Motion.rate(floor_friction_halflife) * friction_modifiers.product()


func get_ground_speed(base: float) -> float:
	return (
			(ground_speed_override if ground_speed_override > 0.0 else base)
			* get_attribute_scale(&"ground_speed_scale")
	)


func get_ground_acceleration(base: float) -> float:
	return base * get_attribute_scale(&"ground_speed_scale")


func get_air_speed(base: float) -> float:
	return (
			(air_speed_override if air_speed_override > 0.0 else base)
			* get_attribute_scale(&"air_speed_scale")
	)


func get_jump_speed(base: float) -> float:
	return base * get_attribute_scale(&"jump_strength_scale")


func get_facing() -> int:
	return -1 if sprite.flip_h else 1


func get_facing_velocity() -> float:
	return velocity.x * get_facing()


func is_moving_with_facing() -> bool:
	return signf(move_input) == float(get_facing())


func is_moving_against_facing() -> bool:
	return signf(move_input) == float(-get_facing())


func is_crouching() -> bool:
	return controls.is_held(&"crouch") and can_crouch()


func can_crouch() -> bool:
	return is_on_floor() and not water.is_on_surface()


func is_swim_pressed(buffer: float) -> bool:
	return controls.was_pressed_within(&"jump", buffer) and not fludd.is_aiming()


func has_landed() -> bool:
	return is_on_floor() and velocity.y >= 0.0


func _integrate(delta: float) -> void:
	var start: Vector2 = velocity
	velocity.y = minf(velocity.y + get_gravity_strength() * delta, get_fall_speed_cap())
	var end: Vector2 = velocity
	velocity.y = (start.y + end.y) * 0.5
	var mid: Vector2 = velocity
	_try_step()
	move_and_slide()
	velocity += end - mid


func _update_collision() -> void:
	var target: CollisionShape2D = base_collision
	for state: State in machine.get_active_states():
		var shape: CollisionShape2D = (state as PlayerState).collision_shape
		if shape:
			target = shape
	
	if target == _collision or _collision and not _has_room_for(target):
		return
	
	_collision = target
	for shape: CollisionShape2D in collision_shapes:
		shape.disabled = shape != target


func _has_room_for(shape: CollisionShape2D) -> bool:
	var grown: Rect2 = _get_shape_rect(shape)
	var current: Rect2 = _get_shape_rect(_collision)
	if grown.position.y >= current.position.y:
		return true
	
	var gap: RectangleShape2D = RectangleShape2D.new()
	gap.size = Vector2(grown.size.x - 1.0, current.position.y - grown.position.y)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = gap
	query.transform = global_transform.translated_local(
			Vector2(grown.get_center().x, grown.position.y + gap.size.y * 0.5)
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var body: CollisionObject2D = hit.get("collider") as CollisionObject2D
		if not body or not body.is_shape_owner_one_way_collision_enabled(
				body.shape_find_owner(hit.get("shape"))
		):
			return false
	
	return true


func _get_shape_rect(shape: CollisionShape2D) -> Rect2:
	var rect: Rect2 = shape.shape.get_rect()
	return Rect2(shape.position + rect.position, rect.size)


func _on_feet_landed(hurt_box: HurtBox) -> void:
	if velocity.y < 0.0 or machine.is_active(&"Stomp") or ground_pound.is_active():
		return
	if carry.ignores(hurt_box.owner):
		return
	
	var dive: DiveState = machine.get_state() as DiveState
	if dive:
		dive.stomp()
		return
	
	machine.change_state(&"Stomp")
