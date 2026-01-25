extends Node2D
class_name Combatant

signal hp_changed(current: int, max_hp: int)
signal ap_changed(current: int, max_ap: int)

@export var combatant_data: CombatantData
@onready var sprite: AnimatedSprite2D = $Animacion

var current_hp: int
var current_ap: int
var is_alive: bool = true


func _ready():
	await get_tree().process_frame

	if combatant_data == null:
		push_error("%s no tiene CombatantData asignado" % name)
		return

	current_hp = combatant_data.max_hp
	current_ap = combatant_data.max_ap
	is_alive = true
	play_animation("idle")
	
	emit_signal("hp_changed", current_hp, combatant_data.max_hp)
	emit_signal("ap_changed", current_ap, combatant_data.max_ap)


# ================================
# DAMAGE & LIFE STATE
# ================================

func apply_damage(amount: int) -> void:
	if not is_alive:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)

	print("%s recibe %d daño (HP: %d)" % [name, amount, current_hp])

	if current_hp <= 0:
		_die()
	else:
		await play_animation("hit")
		
	emit_signal("hp_changed", current_hp, combatant_data.max_hp)


func _die() -> void:
	is_alive = false
	await play_animation("death")
	emit_signal("hp_changed", current_hp, combatant_data.max_hp)


# ================================
# ANIMATIONS
# ================================

func play_animation(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		push_warning("%s no tiene AnimatedSprite2D o SpriteFrames" % name)
		return

	if sprite.sprite_frames.has_animation(anim_name):
		print(name, " → anim:", anim_name)
		sprite.play(anim_name)
		await sprite.animation_finished
	else:
		push_warning("%s no tiene la animación '%s'" % [name, anim_name])
