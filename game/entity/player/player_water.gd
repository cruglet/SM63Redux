class_name PlayerWater
extends Node

@export var player: Player
@export var gravity_scale: float = 0.1
@export_flags_2d_physics var surface_layers: int = 8192
@export var bus_effects: Array[AudioEffect]
@export_group("Splash", "splash_")
@export var splash_scene: PackedScene
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var splash_min_speed: float = 60.0


func set_surface_solid(solid: bool) -> void:
	if solid:
		player.collision_mask |= surface_layers
		player.floor_raycast.collision_mask |= surface_layers
	else:
		player.collision_mask &= ~surface_layers
		player.floor_raycast.collision_mask &= ~surface_layers


func is_on_surface() -> bool:
	if not player.is_on_floor():
		return false
	
	var below: CollisionObject2D = player.floor_raycast.get_collider() as CollisionObject2D
	if below and below.collision_layer & surface_layers:
		return true
	
	for i: int in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		var body: CollisionObject2D = collision.get_collider() as CollisionObject2D
		if body and body.collision_layer & surface_layers:
			return true
	
	return false


func _on_water_entered() -> void:
	_splash()
	if player.has_cap(&"ignores_water"):
		player.velocity *= player.get_attribute_scale(&"water_entry_damping")
	for effect: AudioEffect in bus_effects:
		AudioServer.add_bus_effect(0, effect)


func _on_water_exited() -> void:
	_splash()
	for effect: AudioEffect in bus_effects:
		for i: int in range(AudioServer.get_bus_effect_count(0) - 1, -1, -1):
			if AudioServer.get_bus_effect(0, i) == effect:
				AudioServer.remove_bus_effect(0, i)
				break


func _splash() -> void:
	if not splash_scene or absf(player.velocity.y) < splash_min_speed:
		return
	
	var splash: WaterSplash = splash_scene.instantiate() as WaterSplash
	splash.speed = absf(player.velocity.y)
	Spawner.spawn_near(player.water_check, splash)
