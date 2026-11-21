class_name ShineGetBanner
extends Control

const SPACE: int = 32

@export var text: String = "SHINE GET!"
@export var font: Font
@export var title_font: Font
@export var font_size: int = 32
@export var text_scale: float = 2.0
@export var title_scale: float = 1.0
@export var outline_size: int = 4
@export var outline_color: Color = Color.BLACK
@export_range(0.0, 1.0) var height_ratio: float = 0.32
@export var line_spacing: float = 2.0
@export_group("Music")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var beat: float = 0.2496
@export var letter_times: PackedFloat32Array = [
	0.006,
	0.244,
	0.493,
	0.621,
	0.993,
	1.132,
	1.254,
	1.37,
	1.741,
]
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var title_time: float = 2.003
@export var accent_times: PackedFloat32Array = [0.993, 1.741, 2.003, 2.38]
@export_group("Entrance")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pop_duration: float = 0.25
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var drop_height: float = 40.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var drop_tilt: float = 25.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var title_stagger: float = 0.02
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var title_rise: float = -16.0
@export_group("Jaunt")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var hop_height: float = 3.0
@export var beats_per_hop: float = 2.0
@export var hop_spread: float = 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var tilt: float = 6.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var accent_height: float = 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var accent_duration: float = 0.22
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var accent_ripple: float = 0.015
@export var title_jaunt: float = 0.4
@export_group("Exit")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var exit_stagger: float = 0.03
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var exit_duration: float = 0.2

var _title: String = ""
var _time: float = 0.0
var _left_at: float = INF


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= _left_at + exit_stagger * text.length() + exit_duration:
		hide()
		set_process(false)


func _draw() -> void:
	var text_height: float = font.get_height(font_size) * text_scale
	var title_height: float = title_font.get_height(font_size) * title_scale
	var text_y: float = size.y * height_ratio
	var title_y: float = text_y + (text_height + title_height) * 0.5 + line_spacing
	_draw_line(text, font, text_y, text_scale, _letter_time, drop_height, 1.0)
	_draw_line(_title, title_font, title_y, title_scale, _title_time, title_rise, title_jaunt)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func play(title: String) -> void:
	_title = title
	_time = 0.0
	_left_at = INF
	show()
	set_process(true)
	queue_redraw()


func leave() -> void:
	if visible and is_inf(_left_at):
		_left_at = _time


func _draw_line(
		line: String,
		line_font: Font,
		center_y: float,
		line_scale: float,
		start_of: Callable,
		travel: float,
		jaunt: float,
) -> void:
	var x: float = (size.x - _line_width(line, line_font) * line_scale) * 0.5
	var baseline: float = line_font.get_ascent(font_size) - line_font.get_height(font_size) * 0.5
	var canvas: RID = get_canvas_item()
	var hop_rate: float = PI / (beat * beats_per_hop)
	var glyph: int = 0
	for i: int in line.length():
		var character: int = line.unicode_at(i)
		var width: float = _advance(character, line_font)
		var center: Vector2 = Vector2(x + width * line_scale * 0.5, center_y)
		x += width * line_scale
		if character == SPACE:
			continue
		
		var start: float = start_of.call(glyph)
		glyph += 1
		var entrance: float = _progress(_time - start, pop_duration)
		var pop: float = _ease(entrance, Tween.TRANS_BACK)
		var scale_amount: float = pop * _exit_scale(i) * line_scale
		if scale_amount <= 0.0:
			continue
		
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var hop: float = absf(sin(_time * hop_rate - i * hop_spread)) * hop_height
		var lift: float = (hop + _accent_lift(start, i)) * jaunt * entrance
		var offset: float = (1.0 - _ease(entrance, Tween.TRANS_BOUNCE)) * travel + lift
		var wobble: float = sin(_time * hop_rate * 0.5 + i * 1.3) * tilt * jaunt * entrance
		draw_set_transform(
				center - Vector2(0.0, offset),
				deg_to_rad((1.0 - pop) * drop_tilt * side + wobble),
				Vector2.ONE * scale_amount,
		)
		var origin: Vector2 = Vector2(-width * 0.5, baseline)
		line_font.draw_char_outline(
				canvas,
				origin,
				character,
				font_size,
				outline_size,
				outline_color,
		)
		line_font.draw_char(canvas, origin, character, font_size)


func _letter_time(glyph: int) -> float:
	if letter_times.is_empty():
		return glyph * beat
	if glyph < letter_times.size():
		return letter_times.get(glyph)
	return letter_times.get(letter_times.size() - 1) + (glyph - letter_times.size() + 1) * beat


func _title_time(glyph: int) -> float:
	return title_time + glyph * title_stagger


func _accent_lift(start: float, index: int) -> float:
	var lift: float = 0.0
	for accent: float in accent_times:
		var elapsed: float = _time - accent - index * accent_ripple
		if accent > start and elapsed >= 0.0 and elapsed < accent_duration:
			lift += sin(PI * elapsed / accent_duration) * accent_height
	return lift


func _line_width(line: String, line_font: Font) -> float:
	var width: float = 0.0
	for i: int in line.length():
		width += _advance(line.unicode_at(i), line_font)
	return width


func _advance(character: int, line_font: Font) -> float:
	var source: Font = line_font if line_font.has_char(character) else font
	return source.get_char_size(character, font_size).x


func _exit_scale(index: int) -> float:
	if is_inf(_left_at):
		return 1.0
	
	var leaving: float = _progress(_time - _left_at - exit_stagger * index, exit_duration)
	return 1.0 - Tween.interpolate_value(0.0, 1.0, leaving, 1.0, Tween.TRANS_BACK, Tween.EASE_IN)


func _progress(elapsed: float, duration: float) -> float:
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0.0 else float(elapsed >= 0.0)


func _ease(progress: float, transition: Tween.TransitionType) -> float:
	return Tween.interpolate_value(0.0, 1.0, progress, 1.0, transition, Tween.EASE_OUT)
