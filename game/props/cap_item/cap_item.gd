class_name CapItem
extends Entity

const PICKUP_SFX_DB: float = -10.0

@export var cap: StringName = &""
@export var collect_sfx: AudioStream


func _on_entity_check_area_player_entered(player: Player) -> void:
	player.caps.end(cap)
	player.caps.start(cap)
	#if collect_sfx:
		#SFX.build(collect_sfx).set_db(PICKUP_SFX_DB).play()
	queue_free()
