class_name GhostPose
extends RefCounted

var time: float = 0.0
var textures: Array[Texture2D] = []
var rects: Array[Rect2] = []
var regions: Array[Rect2] = []
var transforms: Array[Transform2D] = []


static func capture(player: Player, space: Node2D, at_time: float) -> GhostPose:
	var pose: GhostPose = GhostPose.new()
	pose.time = at_time
	var to_space: Transform2D = space.get_global_transform().affine_inverse()
	for layer: RigLayer in player.sprite.get_layers():
		if not layer.texture or not layer.is_visible_in_tree():
			continue
		
		pose.textures.append(layer.texture)
		pose.rects.append(layer.get_rect())
		pose.regions.append(
				layer.region_rect
				if layer.region_enabled
				else Rect2(Vector2.ZERO, layer.texture.get_size())
		)
		pose.transforms.append(to_space * layer.get_global_transform())
	
	return pose


func resembles(other: GhostPose) -> bool:
	return (
			regions == other.regions
			and textures == other.textures
			and transforms.size() == other.transforms.size()
			and (
					transforms.is_empty()
					or transforms[0].origin.distance_squared_to(other.transforms[0].origin) < 1.0
			)
	)
