extends Entity

const FLUDD_PICKUP_COLLECT: AudioStream = preload("uid://skajv0eggseb")
const PICKUP_SFX_DB: float = -10.0

@export var grant_nozzle: PlayerFludd.Nozzle = PlayerFludd.Nozzle.HOVER


func _on_entity_check_area_player_entered(player: Player) -> void:
	player.fludd.collect_nozzle(grant_nozzle)
	SFX.build(FLUDD_PICKUP_COLLECT).set_db(PICKUP_SFX_DB).play()
	queue_free()
