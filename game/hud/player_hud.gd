class_name PlayerHUD
extends CanvasLayer

@export var player: Player
@export var health_meter: HealthMeter
@export var fludd_meter: FluddMeter
@export var coin_counters: Dictionary[StringName, CoinCounter] = {}
@export var shine_banner: ShineGetBanner


func _ready() -> void:
	if player:
		bind(player)


func bind(target: Player) -> void:
	player = target
	health_meter.bind(target.get_component(HealthComponent) as HealthComponent)
	health_meter.bind_caps(target.caps)
	fludd_meter.bind(target.fludd)
	if not target.shine_get.celebration_started.is_connected(_on_shine_celebrated):
		target.shine_get.celebration_started.connect(_on_shine_celebrated)
		target.shine_get.celebration_ended.connect(shine_banner.leave)


func set_coins(kind: StringName, count: int, total: int = 0) -> void:
	var counter: CoinCounter = coin_counters.get(kind)
	if counter:
		counter.set_count(count, total)


func _on_shine_celebrated() -> void:
	var level: Level = Level.of(self)
	shine_banner.play(level.get_scenario_name() if level else "")
