class_name PlayerDetectorComponent
extends EntityComponent


@export var detection_area: Area2D
@export var alert_state: StringName = &"Chase"
@export var ignored_states: Array[StringName] = []
@export_flags_2d_physics var sight_blockers: int = 2
@export_group("Losing Target")
@export var aggro_states: Array[StringName] = []
@export var lost_state: StringName
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var give_up_distance: float = 320.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var memory_time: float = 2.0

var target: Player

var _candidate: Player
var _unseen_time: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	if detection_area:
		detection_area.area_entered.connect(_on_detection_area_entered)
		detection_area.area_exited.connect(_on_detection_area_exited)


func _physics_process(delta: float) -> void:
	if target:
		_track(delta)
	elif is_instance_valid(_candidate) and _candidate.is_detectable() and can_see(_candidate):
		_detect(_candidate)
	
	set_physics_process(target != null or is_instance_valid(_candidate))


func has_target() -> bool:
	return is_instance_valid(target) and target.is_detectable()


func can_see(player: Player) -> bool:
	if sight_blockers == 0:
		return true
	
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			entity.global_position,
			player.global_position,
			sight_blockers,
			[entity.get_rid()],
	)
	return entity.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func forget() -> void:
	target = null
	_unseen_time = 0.0
	if not lost_state.is_empty() and entity.machine.get_state_name() in aggro_states:
		entity.machine.change_state(lost_state)


func _track(delta: float) -> void:
	if not has_target() or _is_out_of_range(target):
		forget()
		return
	
	_unseen_time = 0.0 if can_see(target) else _unseen_time + delta
	if _unseen_time >= memory_time:
		forget()


func _is_out_of_range(player: Player) -> bool:
	return (
			give_up_distance > 0.0
			and entity.global_position.distance_to(player.global_position) > give_up_distance
	)


func _detect(player: Player) -> void:
	if not enabled or entity.machine.get_state_name() in ignored_states:
		return
	
	target = player
	_unseen_time = 0.0
	entity.sprite.flip_h = target.global_position.x < entity.global_position.x
	entity.machine.change_state(alert_state)


func _on_detection_area_entered(area: Area2D) -> void:
	var player: Player = area.owner as Player
	if not area.has_meta(&"player") or not player:
		return
	
	_candidate = player
	set_physics_process(true)


func _on_detection_area_exited(area: Area2D) -> void:
	if area.owner == _candidate:
		_candidate = null
