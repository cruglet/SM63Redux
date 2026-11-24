extends PlayerState


func _tick(delta: float) -> void:
	player.jumps.tick_chain(delta)
	if player.ground_pound.wants_start():
		machine.change_state(&"GroundPoundStart")


func _next() -> StringName:
	return &"SwimIdle" if player.is_swimming() else &""
