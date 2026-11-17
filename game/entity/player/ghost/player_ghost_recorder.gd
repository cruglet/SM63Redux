class_name PlayerGhostRecorder
extends Node

@export var level: Level
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var interval: float = 0.1

var trail: GhostTrail = GhostTrail.new()

var _time: float = 0.0
var _next_capture: float = 0.0


func _ready() -> void:
	Singleton.editor_session.ghost = trail


func _physics_process(delta: float) -> void:
	_time += delta
	var player: Player = level.get_player()
	if player == null or _time < _next_capture:
		return
	
	_next_capture = _time + interval
	if trail.poses.is_empty():
		trail.area_uuid = level.get_area().uuid
		trail.layer_index = level.get_area().get_layer_of(player.object).index
	var pose: GhostPose = GhostPose.capture(player, player.object.get_parent(), _time)
	trail.record(pose, Settings.level_designer.player_ghost_length.current_value)
