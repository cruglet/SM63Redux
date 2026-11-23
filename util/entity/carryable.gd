class_name Carryable
extends Node

signal picked_up(anchor: Node2D)
signal thrown(velocity: Vector2)
signal dropped
signal released

const GROUP: StringName = &"carryables"

@export var entity: Entity
@export var visual: Node2D
@export var heavy: bool = false
@export var kick_on_touch: bool = false
@export var contact_shape: CollisionShape2D
@export_custom(PROPERTY_HINT_EXPRESSION, "") var carry_expression: String
@export var outline_material: Material
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var carrier_grace: float = 0.2
@export_group("Holding")
@export var hold_offset: Vector2 = Vector2.ZERO
@export_group("Release")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var kick_velocity: Vector2 = Vector2(300.0, -60.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var upkick_velocity: Vector2 = Vector2(0.0, -420.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var throw_velocity: Vector2 = Vector2(250.0, -100.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var drop_velocity: Vector2 = Vector2(60.0, -60.0)

var highlighted: bool = false

var _anchor: Node2D
var _carrier: Node
var _carrier_grace_until: int = 0
var _expression: Expression
var _outlines: Dictionary[Sprite2D, Sprite2D] = {}
var _visual_parent: Node
var _visual_index: int = 0
var _visual_position: Vector2 = Vector2.ZERO
var _visual_inherits: bool = false
var _layer: int = 0
var _mask: int = 0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if not carry_expression.is_empty():
		_expression = Expression.new()
		if _expression.parse(carry_expression) != OK:
			_expression = null
	
	if outline_material and visual:
		for node: Node in visual.find_children("*", "Sprite2D", true, false):
			var outline: Sprite2D = Sprite2D.new()
			outline.material = outline_material
			outline.visible = false
			node.add_child(outline)
			_outlines[node as Sprite2D] = outline


func _process(_delta: float) -> void:
	var shown: bool = highlighted and not _outlines.is_empty() and can_carry()
	for sprite: Sprite2D in _outlines:
		var outline: Sprite2D = _outlines[sprite]
		outline.visible = shown and sprite.texture != null
		if outline.visible:
			_copy_frame(sprite, outline)


func _exit_tree() -> void:
	if not is_carried():
		return
	
	visual.queue_free()
	_anchor = null
	released.emit()


func can_carry() -> bool:
	if is_carried() or not entity or not entity.is_inside_tree():
		return false
	if carry_expression.is_empty():
		return true
	if not _expression:
		return false
	
	var result: Variant = _expression.execute([], entity)
	return not _expression.has_execute_failed() and bool(result)


func get_contact_rect() -> Rect2:
	if contact_shape and contact_shape.shape:
		return contact_shape.global_transform * contact_shape.shape.get_rect()
	
	for child: Node in entity.get_children():
		var shape: CollisionShape2D = child as CollisionShape2D
		if shape and shape.shape and not shape.disabled:
			return shape.global_transform * shape.shape.get_rect()
	return Rect2(entity.global_position, Vector2.ZERO)


func is_carried() -> bool:
	return _anchor != null


func get_anchor() -> Node2D:
	return _anchor


func ignores_hit(hitbox: HitBox) -> bool:
	if is_carried():
		return true
	return (
			is_instance_valid(_carrier)
			and hitbox.owner == _carrier
			and Engine.get_physics_frames() < _carrier_grace_until
	)


func pick_up(anchor: Node2D, carrier: Node) -> void:
	_anchor = anchor
	_carrier = carrier
	_layer = entity.collision_layer
	_mask = entity.collision_mask
	entity.collision_layer = 0
	entity.collision_mask = 0
	entity.velocity = Vector2.ZERO
	entity.disable()
	
	_visual_parent = visual.get_parent()
	_visual_index = visual.get_index()
	_visual_position = visual.position
	_visual_inherits = visual.use_parent_material
	_visual_parent.remove_child(visual)
	anchor.add_child(visual)
	visual.position = hold_offset + _visual_position
	visual.use_parent_material = true
	var rig: SpriteRig2D = visual as SpriteRig2D
	if rig:
		rig.flip_h = false
	follow()
	picked_up.emit(anchor)


func follow() -> void:
	entity.global_position = _anchor.to_global(hold_offset)


func throw(velocity: Vector2, safe_from: Vector2) -> void:
	_release(velocity, safe_from)
	thrown.emit(velocity)


func drop(velocity: Vector2, safe_from: Vector2) -> void:
	_release(velocity, safe_from)
	dropped.emit()


func kick(velocity: Vector2, kicker: Node) -> void:
	_carrier = kicker
	_start_grace()
	entity.velocity = velocity
	thrown.emit(velocity)


func let_go() -> void:
	_release(Vector2.ZERO, entity.global_position)


func _release(velocity: Vector2, safe_from: Vector2) -> void:
	if not is_carried():
		return
	
	var target: Vector2 = _anchor.to_global(hold_offset)
	var facing_left: bool = _anchor.global_transform.x.x < 0.0
	_anchor.remove_child(visual)
	_visual_parent.add_child(visual)
	_visual_parent.move_child(visual, _visual_index)
	visual.position = _visual_position
	visual.use_parent_material = _visual_inherits
	var rig: SpriteRig2D = visual as SpriteRig2D
	if rig:
		rig.flip_h = facing_left
	_anchor = null
	
	entity.collision_layer = _layer
	entity.collision_mask = _mask
	entity.enable()
	entity.global_position = Vector2(safe_from.x, target.y)
	entity.move_and_collide(target - entity.global_position)
	entity.velocity = velocity
	_start_grace()
	released.emit()


func _start_grace() -> void:
	var ticks: int = Engine.physics_ticks_per_second
	_carrier_grace_until = Engine.get_physics_frames() + ceili(carrier_grace * ticks)


func _copy_frame(sprite: Sprite2D, outline: Sprite2D) -> void:
	outline.texture = sprite.texture
	outline.centered = sprite.centered
	outline.offset = sprite.offset
	outline.flip_h = sprite.flip_h
	outline.flip_v = sprite.flip_v
	outline.hframes = sprite.hframes
	outline.vframes = sprite.vframes
	outline.frame = sprite.frame
	outline.region_enabled = sprite.region_enabled
	outline.region_rect = sprite.region_rect
