class_name GhostTrail
extends RefCounted

var area_uuid: StringName = &""
var layer_index: int = 0
var poses: Array[GhostPose] = []


func record(pose: GhostPose, max_age: float) -> void:
	if not poses.is_empty() and poses.back().resembles(pose):
		return
	
	poses.append(pose)
	while poses.front().time < pose.time - max_age:
		poses.pop_front()
