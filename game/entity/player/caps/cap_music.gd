class_name CapMusic
extends AudioStreamPlayer

enum Quantize {
	BEAT,
	BAR,
}

const SILENT_DB: float = -80.0

@export var caps: MultiModeMachine
@export var base: AudioStream
@export var quantize: Quantize = Quantize.BEAT
@export var fade_beats: float = 1.0

var _layers: Array[CapMode] = []
var _mix: AudioStreamSynchronized
var _levels: PackedFloat32Array = []
var _targets: PackedFloat32Array = []
var _wanted: PackedFloat32Array = []
var _switch_beat: float = -1.0
var _last_beat: float = 0.0


func _ready() -> void:
	_mix = AudioStreamSynchronized.new()
	_mix.stream_count = 1
	_mix.set_sync_stream(0, base)
	for child: Node in caps.get_children():
		var cap: CapMode = child as CapMode
		if cap and cap.music:
			_layers.append(cap)
			_mix.stream_count += 1
			_mix.set_sync_stream(_mix.stream_count - 1, cap.music)
	_levels.resize(_mix.stream_count)
	_targets = _levels.duplicate()
	_wanted = _levels.duplicate()
	_apply_levels()
	stream = _mix


func _process(delta: float) -> void:
	var wanted: PackedFloat32Array = _get_wanted()
	if not playing:
		if wanted[0] > 0.0:
			_start(wanted)
		return
	
	var beat: float = _get_beat()
	if wanted != _wanted:
		_wanted = wanted
		_switch_beat = _next_boundary(beat)
	if _switch_beat >= 0.0 and _crossed(_switch_beat, beat):
		_switch_beat = -1.0
		_targets = _wanted
	_last_beat = beat
	_fade(delta)
	if _levels[0] <= 0.0 and _targets[0] <= 0.0:
		stop()


func _start(wanted: PackedFloat32Array) -> void:
	_wanted = wanted
	_targets = wanted
	_levels = wanted.duplicate()
	_switch_beat = -1.0
	_last_beat = 0.0
	_apply_levels()
	play()


func _fade(delta: float) -> void:
	var beats: float = delta * _get_beat_info(&"bpm") / 60.0
	var step: float = beats / fade_beats if fade_beats > 0.0 else INF
	for i: int in _levels.size():
		_levels[i] = move_toward(_levels[i], _targets[i], step)
	_apply_levels()


func _apply_levels() -> void:
	for i: int in _levels.size():
		_mix.set_sync_stream_volume(i, maxf(linear_to_db(_levels[i]), SILENT_DB))


func _get_wanted() -> PackedFloat32Array:
	var wanted: PackedFloat32Array = [0.0]
	for cap: CapMode in _layers:
		var on: bool = cap.is_running()
		wanted.append(1.0 if on else 0.0)
		if on:
			wanted[0] = 1.0
	return wanted


func _get_beat() -> float:
	var time: float = get_playback_position() + AudioServer.get_time_since_last_mix()
	var beat: float = time * _get_beat_info(&"bpm") / 60.0
	var count: float = _get_beat_info(&"beat_count")
	return fmod(beat, count) if count > 0.0 else beat


func _next_boundary(beat: float) -> float:
	var unit: float = _get_beat_info(&"bar_beats") if quantize == Quantize.BAR else 1.0
	var boundary: float = (floorf(beat / unit) + 1.0) * unit
	var count: float = _get_beat_info(&"beat_count")
	return fmod(boundary, count) if count > 0.0 else boundary


func _crossed(target: float, beat: float) -> bool:
	if _last_beat - beat < _get_beat_info(&"beat_count") * 0.5:
		return _last_beat < target and target <= beat
	return target > _last_beat or target <= beat


func _get_beat_info(property: StringName) -> float:
	return float(base.get(property))
