class_name JumpState
extends PlayerState

@export_group("Launch")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var strength: float = 332.5
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var required_speed: float = 0.0
@export_group("Release")
@export_range(0.0, 1.0) var cut_multiplier: float = 0.75
@export_group("Chain")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var chain_window: float = 0.15
@export_group("Spin")
@export var can_spin: bool = true
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var spin_min_speed: float = -55.0
@export_group("Glide")
@export_range(-1.0, 1.0, 0.01) var glide_after: float = -1.0


func _next() -> StringName:
	if (
			glide_after >= 0.0
			and player.can_glide()
			and player.velocity.y
			> -player.get_jump_speed(strength) * (1.0 - glide_after)
	):
		return &"Glide"
	return (
			&"Spin"
			if can_spin
			and controls.is_held(&"spin")
			and player.velocity.y > spin_min_speed
			else &""
	)


func can_chain() -> bool:
	return (
			required_speed <= 0.0
			or player.has_cap(&"free_jump_chain")
			or absf(player.velocity.x) >= required_speed
			and player.is_moving_with_facing()
	)
