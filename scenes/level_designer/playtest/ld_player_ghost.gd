class_name LDPlayerGhost
extends LDComponent

@export var toggle_button: BaseButton

var _view: GhostTrailView


func _setup() -> void:
	var level: LDLevelHandler = editor.level_handler
	toggle_button.toggled.connect(_refresh.bind(true).unbind(1))
	editor.resumed.connect(_refresh.bind(true))
	level.area_changed.connect(_refresh.unbind(1))
	level.structure_changed.connect(_refresh)
	level.level_opened.connect(_on_level_opened)


func _refresh(animate: bool = false) -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	
	var trail: GhostTrail = Singleton.editor_session.ghost
	var area: LevelArea = editor.level_handler.active_area
	if not toggle_button.button_pressed or trail == null or area == null:
		return
	
	var layer: LevelLayer = area.get_layer(trail.layer_index)
	if trail.area_uuid != area.uuid or layer == null:
		return
	
	_view = GhostTrailView.new()
	_view.trail = trail
	layer.add_overlay(_view)
	if animate and Settings.ui.animations.current_value:
		_view.pop_in()


func _on_level_opened() -> void:
	Singleton.editor_session.ghost = null
	_refresh()
