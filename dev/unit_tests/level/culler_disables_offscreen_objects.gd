static func run_test() -> void:
	var tree: SceneTree = Engine.get_main_loop()
	var root: Node2D = Node2D.new()
	var culler: LevelCuller = LevelCuller.new()
	culler.frames_between_updates = 1
	root.add_child(culler)
	tree.root.add_child(root)
	
	var region_data: ObjectData = ObjectData.create(&"music_region")
	region_data.shape = {
		"outer": PackedVector2Array(
				[Vector2(-32, -32), Vector2(32, -32), Vector2(32, 32), Vector2(-32, 32)]
		),
		"holes": [],
		"toplines": [],
	}
	var region: GameObject = ObjectRegistry.spawn(region_data, GameObject.Context.GAME)
	var terrain: GameObject = \
			ObjectRegistry.spawn(ObjectData.create(&"terrain_grass"), GameObject.Context.GAME)
	root.add_child(region)
	root.add_child(terrain)
	var region_areas: Array[Node] = region.find_children("*", "Area2D", true, false)
	var terrain_bodies: Array[Node] = terrain.find_children("*", "StaticBody2D", true, false)
	assert(not region_areas.is_empty())
	assert(not terrain_bodies.is_empty())
	
	var water_data: ObjectData = ObjectData.create(&"water")
	water_data.shape = region_data.shape
	var water: GameObject = ObjectRegistry.spawn(water_data, GameObject.Context.GAME)
	root.add_child(water)
	
	culler.track(terrain)
	culler.track(region)
	culler.track(water)
	for body: StaticBody2D in terrain_bodies:
		assert(body.disable_mode != CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE)
	for area: Area2D in region_areas:
		assert(area.disable_mode == CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE)
	
	culler._physics_process(0.0)
	assert(region.process_mode != Node.PROCESS_MODE_DISABLED)
	
	region.position = Vector2(100000.0, 0.0)
	terrain.position = Vector2(100000.0, 0.0)
	water.position = Vector2(100000.0, 0.0)
	culler._physics_process(0.0)
	assert(region.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(terrain.process_mode != Node.PROCESS_MODE_DISABLED)
	assert(water.process_mode != Node.PROCESS_MODE_DISABLED)
	for area: Area2D in region_areas:
		assert(not area.monitoring)
	
	region.position = \
			culler.get_viewport().get_visible_rect().end + Vector2.ONE * (culler.margin - 1.0)
	culler._physics_process(0.0)
	assert(region.process_mode == Node.PROCESS_MODE_INHERIT)
	for area: Area2D in region_areas:
		assert(area.monitoring)
	
	culler.frames_between_updates = 3
	region.position = Vector2(100000.0, 0.0)
	culler._physics_process(0.0)
	culler._physics_process(0.0)
	assert(region.process_mode == Node.PROCESS_MODE_INHERIT)
	culler._physics_process(0.0)
	culler._physics_process(0.0)
	culler._physics_process(0.0)
	assert(region.process_mode == Node.PROCESS_MODE_DISABLED)
	
	region.free()
	culler.frames_between_updates = 1
	culler._physics_process(0.0)
	root.free()
