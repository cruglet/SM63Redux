extends Prop

@export var break_sfx: AudioStreamPlayer2D
@export var textures: Array[Texture2D]
@export var debris: AnimatedParticles
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var hurt_box: HurtBox
@export var contents: Drop
@export var cleanup_delay: float = 2.0


func _on_init() -> void:
	if not textures.is_empty():
		sprite.texture = textures.pick_random()
	contents.count = get_property(&"coin_amount", contents.count)


func destroy() -> void:
	sprite.hide()
	break_sfx.play()
	collision_shape.set_deferred(&"disabled", true)
	hurt_box.disable()
	debris.burst()
	contents.release()
	get_tree().create_timer(cleanup_delay).timeout.connect(queue_free)


func _on_hurt_box_damaged(_source_hitbox: HitBox) -> void:
	destroy()
