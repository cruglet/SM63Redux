extends State

## The loose shell: slides until friction stops it, bounces off walls, and spins
## at the speed it is travelling. Walls are not allowed to block the floor here,
## so a shell sliding into a step keeps its footing instead of catching on it.


const SPIN_SPEED_DIVISOR: float = 60.0
## Below this the shell would take a very long time to coast to a stop, so it is
## simply stopped.
const STOP_THRESHOLD: float = 4.0
const FRICTION_KEY: StringName = &"shell"
const FRICTION_SCALE: float = 0.03
const WATER_KEY: StringName = &"shell_water"

@export var water_drag: float = 1.5
@export var water_weight: float = 1.8
@export var water_rise_drag: float = 6.0


var _floor_block_backup: bool = true


func _enter() -> void:
	_floor_block_backup = entity.floor_block_on_wall
	entity.floor_block_on_wall = false
	var friction: FrictionComponent = entity.get_component(FrictionComponent) as FrictionComponent
	if friction:
		friction.modifiers.set_modifier(FRICTION_KEY, FRICTION_SCALE)


func _exit() -> void:
	entity.floor_block_on_wall = _floor_block_backup
	var friction: FrictionComponent = entity.get_component(FrictionComponent) as FrictionComponent
	if friction:
		friction.modifiers.clear_modifier(FRICTION_KEY)
	var gravity: GravityComponent = entity.get_component(GravityComponent) as GravityComponent
	if gravity:
		gravity.clear_modifier(WATER_KEY)


func _tick(delta: float) -> void:
	_apply_water(delta)
	var koopa: Koopa = entity as Koopa
	if koopa and koopa.settle_on_landing and entity.is_on_floor():
		koopa.settle_on_landing = false
		entity.velocity.x = 0.0
	
	var speed: float = entity.last_move_velocity.x
	var normal: float = entity.get_wall_normal().x if entity.is_on_wall() else 0.0
	if normal * speed < 0.0:
		entity.velocity.x = absf(speed) * signf(normal)
	
	if absf(entity.velocity.x) <= STOP_THRESHOLD:
		entity.velocity.x = 0.0
	
	if not is_zero_approx(entity.velocity.x):
		sprite.flip_h = entity.velocity.x < 0.0
	sprite.speed_scale = absf(entity.velocity.x) / SPIN_SPEED_DIVISOR


func _apply_water(delta: float) -> void:
	var submerged: bool = entity.water_check != null and entity.is_in_water()
	var gravity: GravityComponent = entity.get_component(GravityComponent) as GravityComponent
	if gravity and submerged:
		gravity.set_modifier(WATER_KEY, water_weight)
	elif gravity:
		gravity.clear_modifier(WATER_KEY)
	if submerged:
		var rise_drag: float = water_rise_drag if entity.velocity.y < 0.0 else water_drag
		entity.velocity.x *= exp(-water_drag * delta)
		entity.velocity.y *= exp(-rise_drag * delta)
