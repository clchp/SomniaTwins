extends Node
class_name TurnSystem

signal turn_started(combatant: Combatant)

var combatants: Array[Combatant] = []
var current_index: int = 0


# ================================
# SETUP
# ================================

func setup(list: Array[Combatant]) -> void:
	combatants = list.duplicate()
	current_index = 0


func start() -> void:
	if combatants.is_empty():
		push_error("TurnSystem: no hay combatants")
		return

	_start_current_turn()


# ================================
# TURN FLOW
# ================================

func end_turn() -> void:
	current_index += 1

	if current_index >= combatants.size():
		current_index = 0

	_start_current_turn()


func _start_current_turn() -> void:
	if combatants.is_empty():
		return

	var checked := 0

	while checked < combatants.size():
		var current: Combatant = combatants[current_index]

		# Si el combatiente no existe o está muerto, saltar
		if current == null or not current.is_alive:
			current_index += 1
			if current_index >= combatants.size():
				current_index = 0
			checked += 1
			continue

		# Combatiente válido
		turn_started.emit(current)
		return

	# si se llega aquí, nadie puede actuar
	push_warning("TurnSystem: no hay combatientes vivos")
