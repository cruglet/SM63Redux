class_name LDSpawnNavigation
extends LDComponent

@export var previous_button: BaseButton
@export var next_button: BaseButton
@export var spawn_label: Label


func _setup() -> void:
	var level: LDLevelHandler = editor.level_handler
	LD.bind_button(previous_button, level.step_spawn.bind(-1))
	LD.bind_button(next_button, level.step_spawn.bind(1))
	level.spawn_changed.connect(_refresh)
	editor.object_handler.objects_changed.connect(_refresh)


func _refresh() -> void:
	var level: LDLevelHandler = editor.level_handler
	if level.active_area == null:
		return
	
	var spawns: Array[GameObject] = level.get_spawns()
	var active: GameObject = level.get_active_spawn()
	for spawn: GameObject in spawns:
		spawn.get_node(^"Editor/Marker").visible = spawn != active
		spawn.get_node(^"Editor/Mario").visible = spawn == active
	spawn_label.text = level.get_spawn_label(active)
	LD.set_disabled(previous_button, active == null)
	LD.set_disabled(next_button, spawns.is_empty() or active == spawns.back())
