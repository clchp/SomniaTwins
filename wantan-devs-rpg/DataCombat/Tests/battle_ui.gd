extends CanvasLayer
class_name BattleUI

signal action_selected(attack_data)

const PANEL_SCENE = preload("res://UI/PlayerPanel.tscn")
const ACTION_PANEL_SCENE = preload("res://UI/action_panel.tscn")

@onready var player_container = $PlayerContainer
@onready var main_action_panel = $MainActionPanel

var current_combatant: Combatant
var current_action_panel: Node = null

# ================================
# ACCIONES
# ================================
func show_actions(combatant: Combatant) -> void:
	# 🔥 TOGGLE: si ya existe, cerrarlo
	if current_action_panel:
		_close_action_panel()
		return
		
	current_combatant = combatant

	current_action_panel = ACTION_PANEL_SCENE.instantiate()
	add_child(current_action_panel)
	
	current_action_panel.position = Vector2(302, 139)

	current_action_panel.attack_pressed.connect(_on_attack_pressed)
	current_action_panel.show_panel()

func hide_actions() -> void:
	if current_action_panel:
		current_action_panel.queue_free()
		current_action_panel = null

	main_action_panel.hide()

func _on_attack_pressed() -> void:
	if current_combatant == null:
		return

	var attack := _get_basic_attack(current_combatant)
	if attack == null:
		push_error("No se encontró ataque básico")
		return
	hide_actions()
	action_selected.emit(attack)

# ================================
# BIND DE COMBATANTS A HUD
# ================================
func bind_combatants(combatants: Array[Combatant]) -> void:
	var players: Array[Combatant] = []
	var enemies: Array[Combatant] = []

	for c in combatants:
		if c.combatant_data.is_player:
			players.append(c)
		else:
			enemies.append(c)

	# 🔥 Limpiar paneles actuales del container
	for child in player_container.get_children():
		child.queue_free()

	# 🔥 Crear panel por cada player
	for player in players:
		var panel = PANEL_SCENE.instantiate()
		player_container.add_child(panel)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		panel.setup_as_player()
		panel.bind(player)

# ================================
# RESULTADO
# ================================
func show_result(text: String) -> void:
	print("RESULTADO DE BATALLA:", text)
	hide_actions()

func _close_action_panel():
	if current_action_panel:
		current_action_panel.queue_free()
		current_action_panel = null

# ================================
# AUXILIARES
# ================================
func _get_basic_attack(combatant: Combatant) -> AttackData:
	for attack in combatant.combatant_data.attacks:
		if attack.is_basic:
			return attack
	return null
