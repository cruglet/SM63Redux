extends GoombaState


@export var hit_box: HitBox


func _enter() -> void:
	hit_box.set_deferred(&"monitoring", false)
	hit_box.set_deferred(&"monitorable", false)
	sprite.animation_finished.connect(goomba.die, CONNECT_ONE_SHOT)
