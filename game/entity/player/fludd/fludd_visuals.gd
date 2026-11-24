class_name FluddVisuals
extends Node

@export var fludd: PlayerFludd
@export var rig: SpriteRig2D
@export var fludd_layer: RigLayer
@export var plume: SpriteRig2D
@export var plume_particles: GPUParticles2D
@export var variant_axis: StringName = &"nozzle"

var _plume_origin: Vector2 = Vector2.ZERO
var _default_animation: StringName = &""


func _ready() -> void:
	_plume_origin = plume.position
	_default_animation = fludd_layer.default_animation
	fludd.nozzle_changed.connect(_on_nozzle_changed)
	_on_nozzle_changed(fludd.equipped_nozzle)


func _physics_process(_delta: float) -> void:
	var mode: FluddMode = fludd.get_selected_mode()
	var spraying: bool = fludd.is_spraying()
	_place_plume(mode)
	_animate_nozzle(mode, spraying)
	if plume.visible == spraying:
		return
	
	plume.visible = spraying
	plume.playing = spraying
	if spraying:
		plume.current_frame = 0


func _on_nozzle_changed(_nozzle: PlayerFludd.Nozzle) -> void:
	var mode: FluddMode = fludd.get_selected_mode()
	var fludd_tween: Tween = create_tween()
	fludd_tween.tween_property(fludd_layer, ^"offset:y", 3, 0.02)
	fludd_tween.tween_property(fludd_layer, ^"offset:y", 0, 0.05)
	rig.set_variant(variant_axis, mode.fludd_variant if mode else &"")
	if mode and plume.has_animation(mode.plume_animation):
		plume.current_animation = mode.plume_animation


func _animate_nozzle(mode: FluddMode, spraying: bool) -> void:
	var using: bool = spraying and mode != null and not mode.use_animation.is_empty()
	fludd_layer.default_animation = mode.use_animation if using else _default_animation


func _place_plume(mode: FluddMode) -> void:
	var facing: float = float(fludd.player.get_facing())
	var offset: Vector2 = mode.plume_offset if mode else Vector2.ZERO
	plume.position = _plume_origin + offset
	var particle_offset: Vector2 = mode.particle_offset if mode else Vector2.ZERO
	plume_particles.global_position = \
			plume.global_position + Vector2(particle_offset.x * facing, particle_offset.y)
