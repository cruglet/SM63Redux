class_name SilhouetteView
extends Node2D

@export var source: SilhouetteSource

var _occluder: CanvasItem
var _object: GameObject


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visible = false


func _enter_tree() -> void:
	_occluder = get_parent() as CanvasItem
	_object = GameObject.of(_occluder)
	RenderingServer.frame_pre_draw.connect(_follow_anchor)


func _process(_delta: float) -> void:
	_set_active(_overlaps_source())


func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_follow_anchor)
	_set_active(false)


func _draw() -> void:
	if is_instance_valid(source):
		draw_texture(source.get_texture(), -Vector2(source.canvas_size) / 2.0)


func _follow_anchor() -> void:
	if visible and is_instance_valid(source) and is_instance_valid(source.anchor):
		global_transform = source.get_anchor_transform()


func _overlaps_source() -> bool:
	if not is_instance_valid(source) or not is_instance_valid(source.anchor):
		return false
	
	if _object == null:
		return true
	
	var size: Vector2 = Vector2(source.canvas_size)
	return (source.get_anchor_transform() * Rect2(-size / 2.0, size)).intersects(
			_object.get_global_bounds()
	)


func _set_active(active: bool) -> void:
	if visible == active or _occluder == null:
		return
	
	visible = active
	_occluder.clip_children = (
			CanvasItem.CLIP_CHILDREN_AND_DRAW if active else CanvasItem.CLIP_CHILDREN_DISABLED
	)
	_occluder.queue_redraw()
