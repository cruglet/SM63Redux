class_name DropPreview
extends Node2D

@export var drop: Drop
@export var template: SpriteRig2D
@export var max_shown: int = 5


func _ready() -> void:
	_populate.call_deferred()


func _on_hurt_box_damaged(_source_hitbox: HitBox) -> void:
	queue_free()


func _populate() -> void:
	var shown: int = mini(drop.count, max_shown)
	for i: int in shown:
		var copy: SpriteRig2D = template.duplicate() as SpriteRig2D
		add_child(copy)
		copy.show()
		copy.play()
		copy.position += Vector2(
				randi_range(-shown + 1, shown - 1),
				randi_range(-shown + 1, shown - 1),
		)
