class_name WingCap
extends CapMode

@export var state_redirects: Dictionary[String, StringName] = {}
@export var wings: Array[RigLayer] = []
@export var variant_axis: StringName = &"wing_cap"
@export var idle_animation: StringName = &"idle"
@export var flap_animation: StringName = &"flap"


func redirect_state(from: StringName, to: StringName) -> StringName:
	return state_redirects.get("%s>%s" % [from, to], to)


func _show_effect(shown: bool) -> void:
	super(shown)
	player.sprite.set_variant(variant_axis, &"on" if shown else &"")


func set_flapping(flapping: bool) -> void:
	for wing: RigLayer in wings:
		wing.default_animation = flap_animation if flapping else idle_animation


func _exit() -> void:
	super()
	set_flapping(false)
