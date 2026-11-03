class_name Drop
extends Marker2D

@export var scene: PackedScene
@export var count: int = 1
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var spread: float = 0.0
@export var reward: bool = false
@export var behind: bool = false


static func release_all(root: Node, rewards: bool = true) -> void:
	for child: Node in root.get_children():
		var drop: Drop = child as Drop
		if drop:
			drop.release(rewards)


func release(rewards: bool = true) -> void:
	if scene == null or (reward and not rewards):
		return
	
	for i: int in count:
		var offset: Vector2 = (
				Vector2(randf_range(-spread, spread), 0.0)
				if count > 1
				else Vector2.ZERO
		)
		Spawner.spawn_near(self, scene.instantiate(), offset, behind)
