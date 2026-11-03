extends State


const PERIOD: float = 3.0
const AMPLITUDE: float = 35.0

@export var displacement: Curve
@export var floor_check_l: RayCast2D
@export var floor_check_r: RayCast2D

var _phase_shift: float = 0.0


func _tick(_delta: float) -> void:
	if entity.is_path_blocked(signf(entity.velocity.x), floor_check_l, floor_check_r):
		_phase_shift += PI
	
	entity.velocity.x = AMPLITUDE * displacement.sample(sin(time / PERIOD + _phase_shift))
	if not is_zero_approx(entity.velocity.x):
		sprite.flip_h = entity.velocity.x < 0.0
