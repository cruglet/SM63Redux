class_name PlayerAirControl
extends Resource

@export_group("Steering")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var max_speed: float = 190.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2")
var acceleration: float = 765.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2")
var turn_acceleration: float = 2520.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var turn_speed_threshold: float = 10.0
@export_group("Momentum")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s")
var momentum_max_speed: float = 400.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2")
var momentum_acceleration: float = 30.0
@export_group("Drag")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2") var drag: float = 120.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s^2")
var over_speed_drag: float = 300.0
