class_name GhostTrailView
extends CanvasGroup

const APPEAR_INTERVAL: float = 0.04
const MAX_APPEAR_DURATION: float = 1.2

var trail: GhostTrail:
	set(value):
		trail = value
		_canvas.queue_redraw()

var _canvas: Node2D = Node2D.new()
var _shown: int = -1
var _interval: float = 0.0
var _elapsed: float = 0.0


func _init() -> void:
	self_modulate = Color(1.0, 1.0, 1.0, 0.4)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas.draw.connect(_paint)
	add_child(_canvas)
	set_process(false)


func _process(delta: float) -> void:
	if Singleton.is_transitioning():
		return
	
	_elapsed += delta
	var shown: int = mini(floori(_elapsed / _interval) + 1, trail.poses.size())
	if shown != _shown:
		_shown = shown
		_canvas.queue_redraw()
	if _shown == trail.poses.size():
		set_process(false)


func pop_in() -> void:
	if trail == null or trail.poses.is_empty():
		return
	
	_interval = minf(APPEAR_INTERVAL, MAX_APPEAR_DURATION / trail.poses.size())
	_elapsed = 0.0
	_shown = 0
	set_process(true)
	_canvas.queue_redraw()


func _paint() -> void:
	if trail == null:
		return
	
	for pose: GhostPose in trail.poses.slice(0, trail.poses.size() if _shown < 0 else _shown):
		for i: int in pose.textures.size():
			_canvas.draw_set_transform_matrix(pose.transforms.get(i))
			_canvas.draw_texture_rect_region(
					pose.textures.get(i),
					pose.rects.get(i),
					pose.regions.get(i),
			)
	
	_canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
