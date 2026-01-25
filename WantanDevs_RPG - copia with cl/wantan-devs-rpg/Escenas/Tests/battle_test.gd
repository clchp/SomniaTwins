extends Node2D
class_name BattleScene

@onready var turn_system: TurnSystem = $TurnSystem
@onready var executor: BattleActionExecutor = $BattleActionExecutor

@onready var hermano: Combatant = $Combatant/HermanoBatalla
@onready var hermana: Combatant = $Combatant/HermanaBatalla
@onready var enemigo: Combatant = $Combatant/MushroomBatalla

@onready var battle_ui: BattleUI = $BattleUI

var combatants: Array[Combatant] = []
var battle_finished := false
var waiting_for_input := false
var current_combatant: Combatant



func _ready():
	print("BattleScene READY")

	combatants = [hermano, hermana, enemigo]

	turn_system.turn_started.connect(_on_turn_started)
	battle_ui.action_selected.connect(_on_action_selected)
	
	battle_ui.bind_combatants(hermano, hermana, enemigo)

	turn_system.setup(combatants)
	turn_system.start()


# ================================
# TURN FLOW
# ================================

func _on_turn_started(combatant: Combatant) -> void:
	if battle_finished:
		return

	if combatant == null or not combatant.is_alive:
		if not _check_battle_end():
			turn_system.end_turn()
		return

	current_combatant = combatant
	print("\nTurno de:", combatant.name)

	# siempre ocultar UI al iniciar turno
	battle_ui.hide_actions()
	waiting_for_input = false

	if combatant.combatant_data.is_player:
		waiting_for_input = true
		battle_ui.show_actions(combatant)
	else:
		await _execute_enemy_turn(combatant)
		_end_turn_flow()

func _end_turn_flow():
	if _check_battle_end():
		battle_finished = true
		return

	turn_system.end_turn()


# ================================
# PLAYER ACTION
# ================================

func _on_action_selected(attack_data: AttackData):
	if not waiting_for_input:
		return
		
	if not current_combatant.combatant_data.is_player:
		return
		
	waiting_for_input = false
	battle_ui.hide_actions()

	var targets := _get_targets(current_combatant)
	
	if targets.is_empty():
		_end_turn_flow()
		return
		
	await current_combatant.play_animation(attack_data.id)
	
	# respiro para cargar animaciones
	await get_tree().create_timer(0.1).timeout
	
	executor.execute_attack(current_combatant, attack_data, targets)

	if current_combatant.is_alive:
		current_combatant.play_animation("idle")

	_end_turn_flow()

# ================================
# ENEMY ACTION
# ================================

func _execute_enemy_turn(attacker: Combatant) -> void:
	if not attacker.is_alive:
		return
	
	var attack_data := _get_first_attack(attacker)
	if attack_data == null:
		return

	var targets := _get_targets(attacker)
	if targets.is_empty():
		return

	attacker.play_animation(attack_data.id)
	executor.execute_attack(attacker, attack_data, targets)

	if attacker.is_alive:
		attacker.play_animation("idle")


# ================================
# BATTLE END
# ================================

func _check_battle_end() -> bool:
	var players_alive := hermano.is_alive or hermana.is_alive
	var enemy_alive := enemigo.is_alive

	battle_ui.hide_actions()

	if not enemy_alive:
		print("VICTORIA")
		battle_ui.show_result("VICTORIA")
		return true

	if not players_alive:
		print("DERROTA")
		battle_ui.show_result("DERROTA")
		return true

	return false


# ================================
# HELPERS
# ================================

func _get_first_attack(combatant: Combatant) -> AttackData:
	if combatant.combatant_data.attacks.is_empty():
		return null
	return combatant.combatant_data.attacks[0]


func _get_targets(attacker: Combatant) -> Array[Combatant]:
	if attacker == enemigo:
		if hermano.is_alive:
			return [hermano]
		elif hermana.is_alive:
			return [hermana]
	else:
		if enemigo.is_alive:
			return [enemigo]

	return []
