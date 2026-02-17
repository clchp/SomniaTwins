extends Node
class_name TurnSystem

signal turn_started(combatant: Combatant)

var combatants: Array[Combatant] = []
var current_index := 0


func setup(list: Array[Combatant]) -> void:
	combatants = list.duplicate()
	current_index = 0

	for c in combatants:
		if c:
			c.died.connect(_on_combatant_died)


func start() -> void:
	if combatants.is_empty():
		push_error("TurnSystem: no hay combatants")
		return
	_start_current_turn()


func end_turn() -> void:
	current_index += 1
	if current_index >= combatants.size():
		current_index = 0
	_start_current_turn()


func _start_current_turn() -> void:
	if not _has_living_combatants():
		push_warning("TurnSystem: combate terminado")
		return

	var checked := 0
	while checked < combatants.size():
		var current := combatants[current_index]

		if current == null or not current.is_alive:
			current_index = (current_index + 1) % combatants.size()
			checked += 1
			continue

		turn_started.emit(current)
		return


func _has_living_combatants() -> bool:
	for c in combatants:
		if c and c.is_alive:
			return true
	return false


func _on_combatant_died(_combatant: Combatant) -> void:
	pass
