class_name BaseJumpState
extends PlayerState

@export var jumps: Array[JumpState]
@export var particles: AnimatedParticles

var chain: int = 0
var chain_timer: float = 0.0

var _jump: JumpState
var _cut: bool = false


func _enter() -> void:
	var index: int = mini(chain, jumps.size() - 1) if not player.carry.is_holding() else 0
	while index > 0 and not jumps[index].can_chain():
		index -= 1
	
	_jump = jumps[index]
	_cut = false
	particles.burst()
	player.velocity.y = -player.get_jump_speed(_jump.strength)
	chain = index + 1
	chain_timer = _jump.chain_window
	player.can_jump = false


func _tick(_delta: float) -> void:
	if _cut or player.velocity.y >= 0.0 or controls.is_held(&"jump"):
		return
	
	_cut = true
	if player.velocity.y >= -player.get_jump_speed(_jump.strength):
		player.velocity.y *= _jump.cut_multiplier


func _exit() -> void:
	player.can_jump = true


func _next() -> StringName:
	if player.can_dive and time > 0.0 and controls.is_just_pressed(&"dive"):
		return &"Dive"
	if player.velocity.y > 0.0 and not player.is_on_floor():
		return &"Fall"
	if player.has_landed():
		return &"Idle"
	return _jump.name if is_current() else &""


func tick_chain(delta: float) -> void:
	if not player.is_on_floor() or not player.can_jump:
		return
	
	chain_timer = maxf(chain_timer - delta, 0.0)
	if chain_timer <= 0.0:
		chain = 0


func reset_chain() -> void:
	chain = 0
