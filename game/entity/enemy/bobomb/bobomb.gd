class_name Bobomb
extends Entity

const FUSE_BOB_FRAMES: Array[int] = [1, 2, 5, 6]

@export var fuse: SpriteRig2D
@export var key: SpriteRig2D
@export var carryable: Carryable


func _ready() -> void:
	super()
	key.play()


func ignores_hit(hitbox: HitBox) -> bool:
	return carryable != null and carryable.ignores_hit(hitbox)


func can_be_carried() -> bool:
	var state: StringName = machine.get_state_name()
	return state == &"Patrol" or state == &"Chase"


func _on_sprite_frame_changed() -> void:
	fuse.offset = Vector2(0, 1) if sprite.current_frame in FUSE_BOB_FRAMES else Vector2.ZERO
	key.offset = fuse.offset


func _on_carryable_picked_up(_anchor: Node2D) -> void:
	if machine.get_state_name() == &"Patrol":
		machine.change_state(&"Chase")


func _on_carryable_thrown(_velocity: Vector2) -> void:
	machine.change_state(&"Kicked")
