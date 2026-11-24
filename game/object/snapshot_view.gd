@tool
class_name SnapshotView
extends Node2D

@export var source: Node
@export var prefer_icon: bool = true
@export var animate: bool = false


func capture(object: GameObject) -> void:
	if prefer_icon and object.icon:
		var sprite: Sprite2D = Sprite2D.new()
		var atlas: AtlasTexture = object.icon as AtlasTexture
		sprite.texture = atlas.atlas if atlas else object.icon
		add_child(sprite)
		return
	
	if source == null:
		return
	
	var origin: Node = source.get_parent()
	var inverse: Transform2D = GameObject.relative_transform(origin, self).affine_inverse()
	_pose_rigs(source)
	for item: Node2D in _collect(source):
		var copy: Node2D
		if item is SpriteRig2D:
			copy = _copy_rig(item as SpriteRig2D)
		else:
			copy = _copy_sprite(item as Sprite2D)
		copy.transform = inverse * GameObject.relative_transform(origin, item)
		add_child(copy)


func _collect(node: Node) -> Array[Node2D]:
	var items: Array[Node2D] = []
	if node is CanvasItem and not (node as CanvasItem).visible:
		return items
	
	if animate and node is SpriteRig2D:
		items.append(node)
		return items
	
	if node is Sprite2D and (node as Sprite2D).texture:
		items.append(node)
	
	for child: Node in node.get_children():
		items.append_array(_collect(child))
	
	return items


func _copy_rig(rig: SpriteRig2D) -> SpriteRig2D:
	var copy: SpriteRig2D = rig.duplicate() as SpriteRig2D
	copy.material = _get_material(rig)
	copy.use_parent_material = false
	return copy


func _copy_sprite(sprite: Sprite2D) -> Sprite2D:
	var copy: Sprite2D = Sprite2D.new()
	copy.texture = sprite.texture
	copy.centered = sprite.centered
	copy.offset = sprite.offset
	copy.flip_h = sprite.flip_h
	copy.flip_v = sprite.flip_v
	copy.hframes = sprite.hframes
	copy.vframes = sprite.vframes
	copy.frame = sprite.frame
	copy.region_enabled = sprite.region_enabled
	copy.region_rect = sprite.region_rect
	copy.modulate = sprite.modulate
	copy.self_modulate = sprite.self_modulate
	copy.material = _get_material(sprite)
	copy.z_index = sprite.z_index
	return copy


func _pose_rigs(node: Node) -> void:
	if node is SpriteRig2D:
		(node as SpriteRig2D).refresh()
	
	for child: Node in node.get_children():
		_pose_rigs(child)


func _get_material(item: CanvasItem) -> Material:
	var current: CanvasItem = item
	while current and current.use_parent_material:
		current = current.get_parent() as CanvasItem
	
	return current.material if current else null
