extends Prop

const BOUNCE_VELOCITY: float = -200.0

@export var sprite: SpriteRig2D
@export var open_sfx: AudioStreamPlayer2D
@export var hurt_box: HurtBox
@export var contents: Drop

var _opened: bool = false


func _on_hurt_box_damaged(source_hitbox: HitBox) -> void:
	var player: Player = source_hitbox.owner as Player
	if _opened or player == null or player.velocity.y <= 0.0:
		return
	
	_opened = true
	hurt_box.disable()
	player.velocity.y = BOUNCE_VELOCITY
	open_sfx.play()
	sprite.play(&"open")
	contents.release()
	await sprite.animation_finished
	queue_free()
