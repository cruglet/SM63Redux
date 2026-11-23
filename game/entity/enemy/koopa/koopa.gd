class_name Koopa
extends Entity

## The koopa, the parakoopa and the loose shell are one entity in three forms.
## The entry a designer places says which form it wakes up in (see
## [SetupTrait]), and a hit walks it one step down the chain - winged, then
## walking, then shell - by changing state rather than by freeing this object
## and spawning the next one in its place.


enum Form {
	KOOPA,
	PARAKOOPA,
	SHELL,
}


const SHELL_DROP_OFFSET: float = 8.0
const KICK_SPEED: float = 300.0
const LOOSE_SPEED: float = 150.0
const FORM_STATES: Dictionary[Form, StringName] = {
	Form.KOOPA: &"Patrol",
	Form.PARAKOOPA: &"Glide",
	Form.SHELL: &"Shell",
}


## Which form this koopa starts in. Set by the entry that places it.
@export var form: Form = Form.KOOPA

@export_group("Nodes")
@export var sfx_player: AudioStreamPlayer2D
@export var wing_emitter: ParticleEmitter
@export var back_wing_texture: Texture2D
## The boxes each form fights with: one set is live at a time, so the single
## scene can carry the walking body and the shell without both answering the
## same hit.
@export var walker_boxes: Array[Node]
@export var shell_boxes: Array[Node]
@export var carryable: Carryable
@export var kick_particles: AnimatedParticles

var settle_on_landing: bool = false


func _ready() -> void:
	super()
	_apply_form()
	if carryable:
		carryable.dropped.connect(_on_carryable_dropped)
		carryable.thrown.connect(_on_carryable_thrown)


func ignores_hit(hitbox: HitBox) -> bool:
	return carryable != null and carryable.ignores_hit(hitbox)


func is_landed_on_from_above(source_hitbox: HitBox, hurt_box: HurtBox) -> bool:
	if source_hitbox.damage_type != HitBox.DamageType.SQUISH:
		return true
	return _area_center(source_hitbox).y < _area_center(hurt_box).y


func is_shell() -> bool:
	return form == Form.SHELL


func is_loose_shell() -> bool:
	return form == Form.SHELL and absf(velocity.x) < LOOSE_SPEED


## Every hit lands here, whichever box caught it; what it means depends on the
## form being worn.
func _on_hurt_box_damaged(source_hitbox: HitBox) -> void:
	match form:
		Form.SHELL:
			if source_hitbox.damage_type == HitBox.DamageType.SQUISH and not is_loose_shell():
				velocity.x = 0.0
				sfx_player.play()
				_burst_kick_particles(source_hitbox)
			else:
				_kick(source_hitbox)
		Form.PARAKOOPA:
			_shed_wings()
			if source_hitbox.damage_type == HitBox.DamageType.STRIKE:
				_change_form(Form.SHELL)
			else:
				velocity = Vector2.ZERO
				_change_form(Form.KOOPA)
		Form.KOOPA:
			if source_hitbox.damage_type != HitBox.DamageType.STRIKE:
				velocity = Vector2.ZERO
			position.y += SHELL_DROP_OFFSET
			_change_form(Form.SHELL)
	
	source_hitbox.bounce_squisher()


func _change_form(next_form: Form) -> void:
	form = next_form
	_apply_form()
	sfx_player.play()


## Hands the live boxes and the state over to the current form. Also the way the
## form the entry asked for is put on in the first place.
func _apply_form() -> void:
	var shelled: bool = form == Form.SHELL
	for node: Node in walker_boxes:
		_set_box_enabled(node, not shelled)
	for node: Node in shell_boxes:
		_set_box_enabled(node, shelled)
	
	machine.change_state(FORM_STATES[form])


func _set_box_enabled(node: Node, enabled: bool) -> void:
	var hurt_box: HurtBox = node as HurtBox
	if hurt_box:
		if enabled:
			hurt_box.enable()
		else:
			hurt_box.disable()
		return
	
	var hit_box: HitBox = node as HitBox
	if hit_box:
		if enabled:
			hit_box.enable()
		else:
			hit_box.disable()
		return
	
	var shape: CollisionShape2D = node as CollisionShape2D
	if shape:
		shape.set_deferred(&"disabled", not enabled)


## Kicked away from whatever hit it. Read from where the hit came rather than
## from which of a pair of side boxes caught it: a stomp covering the whole
## shell landed on both, and whichever fired last decided the direction. A hit
## landing dead centre sends the shell the way it already faces.
func _kick(source_hitbox: HitBox) -> void:
	var direction: float = signf(global_position.x - source_hitbox.global_position.x)
	if is_zero_approx(direction):
		direction = -1.0 if sprite.flip_h else 1.0
	
	velocity.x = KICK_SPEED * direction
	settle_on_landing = false
	sfx_player.play()
	_burst_kick_particles(source_hitbox)


func _burst_kick_particles(source_hitbox: HitBox) -> void:
	if kick_particles:
		kick_particles.global_position = source_hitbox.global_position.lerp(global_position, 0.5)
		kick_particles.burst()


func _area_center(area: Area2D) -> Vector2:
	for child: Node in area.get_children():
		var shape: CollisionShape2D = child as CollisionShape2D
		if shape and shape.shape and not shape.disabled:
			return (shape.global_transform * shape.shape.get_rect()).get_center()
	return area.global_position


func _on_carryable_dropped() -> void:
	settle_on_landing = true


func _on_carryable_thrown(_velocity: Vector2) -> void:
	settle_on_landing = false


## Copies the idle in-scene emitter into the level as a one-shot wing puff.
## Duplicating on losing the wings rather than in _ready keeps every copy
## parented, so a parakoopa still winged when the level unloads cannot strand
## them outside the tree.
func _shed_wings() -> void:
	_spawn_wing_particle()
	var back_wing: ParticleEmitter = _spawn_wing_particle()
	back_wing.direction = Vector2.LEFT
	back_wing.texture = back_wing_texture


func _spawn_wing_particle() -> ParticleEmitter:
	var emitter: ParticleEmitter = wing_emitter.duplicate()
	emitter.emitting = true
	Spawner.spawn_near(self, emitter)
	
	return emitter
