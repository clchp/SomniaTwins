extends Node2D
class_name Combatant

signal hp_changed(current: int, max_hp: int)
signal ap_changed(current: int, max_ap: int)
signal died(combatant: Combatant)

const FLOATING_TEXT = preload("res://UI/FloatingText.tscn")
const ENEMY_PANEL_SCENE = preload("res://UI/PlayerPanel.tscn")

@export var combatant_data: CombatantData
@onready var sprite: AnimatedSprite2D = $Animacion

var current_hp: int
var current_ap: int
var max_hp: int
var max_ap: int
var is_alive: bool = true

func _ready():
	await get_tree().process_frame

	if combatant_data == null:
		push_error("%s no tiene CombatantData asignado" % name)
		return
	max_hp = combatant_data.max_hp
	max_ap = combatant_data.max_ap
	
	current_hp = combatant_data.max_hp
	current_ap = combatant_data.max_ap
	is_alive = true
	
	if not combatant_data.is_player:
		var panel = ENEMY_PANEL_SCENE.instantiate()
		add_child(panel)
		panel.setup_as_enemy()
		panel.bind(self)

		panel.position = Vector2(-40, -15)
		panel.scale = Vector2(0.3, 0.3)
	
	play_animation("idle")
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("ap_changed", current_ap, max_ap)

# ================================
# DAMAGE & LIFE STATE
# ================================

func apply_damage(amount: int) -> void:
	if not is_alive:
		return

	# 1️⃣ Reproducir animación primero
	play_animation("hit")
	await wait_current_animation()

	# 2️⃣ Luego aplicar daño
	current_hp = max(current_hp - amount, 0)
	emit_signal("hp_changed", current_hp, max_hp)

	# 3️⃣ Luego mostrar número
	_spawn_floating_text("-" + str(amount), Color(1, 0.2, 0.2))

	# 4️⃣ Si muere
	if current_hp <= 0:
		is_alive = false
		play_animation("death")
		await wait_current_animation()
		emit_signal("died", self)
	print("HP DESPUES DEL DAÑO:", current_hp)
	
func heal(amount: int) -> void:
	if not is_alive:
		return
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)
	_spawn_floating_text("+" + str(amount), Color(0.2, 1, 0.2))
	
func recover_ap(amount: int) -> void:
	if amount <= 0:
		return
	current_ap = min(current_ap + amount, max_ap)
	emit_signal("ap_changed", current_ap, max_ap)
	_spawn_floating_text(str(amount), Color(0.0, 0.112, 0.96, 1.0))
	
func use_ap(cost: int) -> bool:
	if current_ap < cost:
		return false

	current_ap -= cost
	emit_signal("ap_changed", current_ap, max_ap)
	return true

# ================================
# ANIMATIONS
# ================================

func play_animation(anim: String) -> bool:
	if sprite == null:
		return false
		
	if not sprite.sprite_frames.has_animation(anim):
		print(name, " no tiene animación:", anim)
		return false
	
	print(name, " → anim:", anim)
	sprite.play(anim)
	return true

func wait_current_animation() -> void:
	if sprite == null:
		return
	await sprite.animation_finished
	
func _spawn_floating_text(text: String, color: Color):
	var ft = FLOATING_TEXT.instantiate()
	get_parent().add_child(ft)
	ft.global_position = global_position + Vector2(0, -28)
	ft.setup(text, color)
	

func can_use_ap(cost: int) -> bool:
	return current_ap >= cost
	
func revive(hp_amount: int) -> void:
	if is_alive:
		return

	current_hp = clamp(hp_amount, 1, max_hp)
	is_alive = true

	play_animation("revive") if sprite.sprite_frames.has_animation("revive") else play_animation("idle")

	print(name, " revive con ", current_hp, " HP")


func recover_ap_percent(percent: float) -> void:
	if percent <= 0.0:
		return

	var amount := int(ceil(max_ap * percent))
	if amount <= 0:
		return

	current_ap = min(current_ap + amount, max_ap)
	emit_signal("ap_changed", current_ap, max_ap)

func play_support_item_animation() -> void:
	if play_animation("use_object"):
		await wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout


func play_heal_animation() -> void:
	if play_animation("use_object"):
		await wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout

func is_enemy() -> bool:
	return not combatant_data.is_player
	
func is_player() -> bool:
	return combatant_data.is_player
	
