class_name Level
extends Node2D

signal loaded
signal coins_changed(kind: StringName, count: int, total: int)
signal shine_collected(scenario: int)
signal kickout_requested
signal retry_requested(clean: bool)
signal exit_requested

enum Context {
	CAMPAIGN,
	PLAYTEST,
}

const ATTACH_BATCH: int = 64
const DEBUG_SPAWN_ID: StringName = &"debug_spawn"

@export var world: Node2D
@export var culler: LevelCuller
@export var camera: LevelCamera
@export var hud: PlayerHUD
@export var silhouette_source: SilhouetteSource
@export var silhouette_material: Material
@export var background: LevelBackground
@export var context: Context = Context.CAMPAIGN

var spawn_override: StringName = &""
var _data: LevelData
var _area: LevelArea
var _area_data: AreaData
var _player: Player
var _time: float = 0.0
var _coins: Dictionary[StringName, Dictionary] = {}
var _pending: Array[GameObject] = []
var _pending_layers: Array[LevelLayer] = []
var _world_frozen: bool = false
var _soft_paused: bool = false
var _debug_spawns: Dictionary[StringName, Vector2] = {}


static func of(node: Node) -> Level:
	var current: Node = node
	while current and not current is Level:
		current = current.get_parent()
	
	return current as Level


func _enter_tree() -> void:
	add_to_group(&"level")


func _physics_process(delta: float) -> void:
	_time += delta


func get_time() -> float:
	return _time


func register_coin(kind: StringName, group: StringName = &"default") -> void:
	var counter: Vector2i = _get_counter(kind, group)
	_set_counter(kind, group, counter + Vector2i(0, 1))


func collect_coin(kind: StringName, amount: int = 1, group: StringName = &"default") -> int:
	var counter: Vector2i = _get_counter(kind, group) + Vector2i(amount, 0)
	_set_counter(kind, group, counter)
	return counter.x


func get_coin_counter(kind: StringName, group: StringName = &"default") -> Vector2i:
	return _get_counter(kind, group)


func collect_shine(scenario: int) -> void:
	shine_collected.emit(scenario)


func request_kickout() -> bool:
	if not kickout_requested.get_connections().is_empty():
		kickout_requested.emit()
		return true
	if can_exit():
		request_exit()
		return true
	return false


func can_retry() -> bool:
	return not retry_requested.get_connections().is_empty()


func request_retry(clean: bool = false) -> void:
	retry_requested.emit(clean)


func can_exit() -> bool:
	return not exit_requested.get_connections().is_empty()


func request_exit() -> void:
	exit_requested.emit()


func set_world_frozen(frozen: bool) -> void:
	_world_frozen = frozen
	if _pending.is_empty():
		_apply_world_frozen()


func set_soft_paused(paused: bool) -> void:
	_soft_paused = paused
	if _pending.is_empty():
		_apply_world_frozen()


func is_soft_paused() -> bool:
	return _soft_paused


func is_world_frozen() -> bool:
	return _world_frozen


func load_data(data: LevelData, area_uuid: StringName = &"") -> void:
	if not Singleton.defer_threaded(prepare.bind(data, area_uuid), attach):
		prepare(data, area_uuid)
		attach(0)


func prepare(data: LevelData, area_uuid: StringName = &"") -> void:
	_data = data
	_area_data = data.find_area(area_uuid)
	if _area_data == null:
		_area_data = data.areas.front()
	_area = LevelArea.build(_area_data, GameObject.Context.GAME)
	_pending.clear()
	_pending_layers.clear()
	_debug_spawns.clear()
	for layer: LevelLayer in _area.get_layers():
		for object: GameObject in layer.get_objects():
			if object.id == DEBUG_SPAWN_ID:
				_debug_spawns[object.uuid] = object.position
				layer.remove_object(object)
				object.free()
				continue
			
			layer.get_objects_root().remove_child(object)
			_pending.append(object)
			_pending_layers.append(layer)


func attach(batch: int = ATTACH_BATCH) -> void:
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(_area)
	background.apply_data(_area_data.background)
	for i: int in _pending.size():
		_pending_layers[i].get_objects_root().add_child(_pending[i])
		if batch > 0 and i % batch == batch - 1:
			await get_tree().process_frame
	
	_pending.clear()
	_pending_layers.clear()
	_apply_world_frozen()
	for object: GameObject in _area.get_all_objects():
		if object.game_root is Player:
			_player = object.game_root
		else:
			_track(object)
	
	if _player:
		_apply_spawn_override()
		_bind_player()
	
	loaded.emit()


func respawn(old: GameObject, data: ObjectData, drops_rewards: bool = false) -> void:
	var layer: LevelLayer = _area.get_layer_of(old)
	var object: GameObject = ObjectRegistry.spawn(data, GameObject.Context.GAME) if layer else null
	if object == null:
		return
	
	var entity: Entity = object.game_root as Entity
	if entity:
		entity.drops_rewards = drops_rewards
	var at: int = layer.remove_object(old)
	old.queue_free()
	layer.add_object(object, at)
	_track(object)
	if _player and _renders_silhouette(layer) and _is_in_front(object):
		_attach_silhouette(object)


func dismantle() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	await Teardown.free_nodes(_area.get_all_objects() if _area else [], get_tree())


func get_level_name() -> String:
	return _data.level_name if _data and not _data.level_name.is_empty() else "Untitled Level"


func get_scenario_name() -> String:
	return "Scenario Name"


func get_scenario_description() -> String:
	return "A short description of what this scenario is about."


func get_area() -> LevelArea:
	return _area


func get_player() -> Player:
	return _player


func _apply_world_frozen() -> void:
	var frozen: bool = _world_frozen or _soft_paused
	world.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	if _player:
		_player.object.process_mode = (
				Node.PROCESS_MODE_ALWAYS
				if _soft_paused and not _world_frozen
				else Node.PROCESS_MODE_INHERIT
		)


func _get_counter(kind: StringName, group: StringName) -> Vector2i:
	return _coins.get_or_add(kind, {}).get(group, Vector2i.ZERO)


func _set_counter(kind: StringName, group: StringName, counter: Vector2i) -> void:
	_coins.get_or_add(kind, {}).set(group, counter)
	var total: Vector2i = Vector2i.ZERO
	for each: Vector2i in _coins[kind].values():
		total += each
	coins_changed.emit(kind, total.x, total.y)


func _track(object: GameObject) -> void:
	if not object.cullable:
		return
	
	culler.track_visuals(object)
	var entity: Entity = object.game_root as Entity
	if entity and not entity.cull_when_offscreen:
		return
	
	var layer: LevelLayer = _area.get_layer_of(object)
	if layer and layer.is_effective_decoration():
		return
	
	if object.game_root is Node2D:
		culler.track(object.game_root)


func _apply_spawn_override() -> void:
	if _debug_spawns.has(spawn_override):
		_player.object.position = _debug_spawns[spawn_override]


func _bind_player() -> void:
	camera.follow(_player)
	hud.bind(_player)
	if not coins_changed.is_connected(hud.set_coins):
		coins_changed.connect(hud.set_coins)
	silhouette_source.anchor = _player
	silhouette_source.targets = _player.silhouette_targets
	silhouette_source.reset_anchor()
	_attach_silhouettes()


func _attach_silhouettes() -> void:
	var in_front: bool = false
	for object: GameObject in _area.get_all_objects():
		if in_front and _renders_silhouette(_area.get_layer_of(object)):
			_attach_silhouette(object)
		in_front = in_front or object == _player.object


func _is_in_front(object: GameObject) -> bool:
	var objects: Array[GameObject] = _area.get_all_objects()
	return objects.find(object) > objects.find(_player.object)


func _renders_silhouette(layer: LevelLayer) -> bool:
	return layer == null or not layer.is_effective_decoration() or layer.silhouette


func _attach_silhouette(object: GameObject) -> void:
	for occluder: CanvasItem in object.get_occluders():
		var view: SilhouetteView = SilhouetteView.new()
		view.source = silhouette_source
		view.material = silhouette_material
		occluder.add_child(view)
