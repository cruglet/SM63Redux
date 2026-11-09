class_name HUDCapEffect
extends Node

@export var cap: StringName
@export var targets: Array[CanvasItem] = []
@export var material: ShaderMaterial
@export var parameter: StringName = &"progress"
@export var progress_clip: ClippingTexture2D
@export var indicators: Array[CanvasItem] = []
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var indicator_fade_time: float = 0.0
@export var indicator_hidden_scale: float = 1.0

var _cap_mode: CapMode
var _base_materials: Dictionary[CanvasItem, Material] = {}
var _rest_scales: Dictionary[CanvasItem, Vector2] = {}
var _indicator_tween: Tween


func _ready() -> void:
	set_process(false)
	for indicator: CanvasItem in indicators:
		_rest_scales[indicator] = indicator.get(&"scale")
	_show_indicators(false, false)


func _process(_delta: float) -> void:
	_set_progress(_cap_mode.get_remaining_ratio())


func bind(caps: MultiModeMachine) -> void:
	_cap_mode = caps.get_mode(cap) as CapMode
	for target: CanvasItem in targets:
		_base_materials[target] = target.material
	
	caps.mode_started.connect(_on_mode_started)
	caps.mode_stopped.connect(_on_mode_stopped)
	if caps.is_running(cap):
		_on_mode_started(_cap_mode)


func _set_progress(value: float) -> void:
	for target: CanvasItem in targets:
		(target.material as ShaderMaterial).set_shader_parameter(parameter, value)
	if progress_clip:
		progress_clip.clip_ratio.y = value


func _show_indicators(shown: bool, animate: bool = true) -> void:
	if _indicator_tween:
		_indicator_tween.kill()
	
	if not animate or indicator_fade_time <= 0.0:
		for indicator: CanvasItem in indicators:
			indicator.visible = shown
			indicator.modulate.a = 1.0
			indicator.set(&"scale", _rest_scales[indicator])
		return
	
	_indicator_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	_indicator_tween.set_ease(Tween.EASE_OUT if shown else Tween.EASE_IN)
	for indicator: CanvasItem in indicators:
		var hidden_scale: Vector2 = _rest_scales[indicator] * indicator_hidden_scale
		if shown and not indicator.visible:
			indicator.modulate.a = 0.0
			indicator.set(&"scale", hidden_scale)
			indicator.visible = true
		_indicator_tween.tween_property(
				indicator,
				^"modulate:a",
				1.0 if shown else 0.0,
				indicator_fade_time,
		)
		_indicator_tween.tween_property(
				indicator,
				^"scale",
				_rest_scales[indicator] if shown else hidden_scale,
				indicator_fade_time,
		)
	if not shown:
		_indicator_tween.chain().tween_callback(_hide_indicators)


func _hide_indicators() -> void:
	for indicator: CanvasItem in indicators:
		indicator.visible = false


func _on_mode_started(mode: Mode) -> void:
	if mode != _cap_mode:
		return
	
	if material:
		for target: CanvasItem in targets:
			target.material = material
	_show_indicators(true)
	set_process(true)
	_process(0.0)


func _on_mode_stopped(mode: Mode) -> void:
	if mode != _cap_mode:
		return
	
	if material:
		for target: CanvasItem in targets:
			target.material = _base_materials[target]
	else:
		_set_progress(0.0)
	_show_indicators(false)
	set_process(false)
