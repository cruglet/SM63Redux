class_name WaterSplash
extends Node2D

@export var small_sound: AudioStream
@export var medium_sound: AudioStream
@export var big_sound: AudioStream
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var medium_speed: float = 180.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var big_speed: float = 380.0

var speed: float = 0.0


func _ready() -> void:
	SFX.play_at(_pick_sound(), global_position, &"SFX")
	queue_free.call_deferred()


func _pick_sound() -> AudioStream:
	if speed >= big_speed:
		return big_sound
	if speed >= medium_speed:
		return medium_sound
	
	return small_sound
