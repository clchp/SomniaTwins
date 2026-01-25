extends Node
class_name BattleActionExecutor


# ======================================
# PUBLIC API
# ======================================

func execute_attack(
	attacker: Combatant,
	attack_data: AttackData,
	targets: Array[Combatant]
) -> void:

	if attacker == null or attack_data == null:
		push_error("BattleActionExecutor: datos inválidos")
		return

	if targets.is_empty():
		push_warning("BattleActionExecutor: no hay objetivos")
		return

	for target in targets:
		if target == null or not target.is_alive:
			continue

		var damage := _calculate_damage(attacker, target, attack_data)
		await target.apply_damage(damage)

		print("%s usa %s sobre %s → %d daño" % [
			attacker.name,
			attack_data.display_name,
			target.name,
			damage
		])
		
	attacker.current_ap -= attack_data.ap_cost
	attacker.current_ap = max(attacker.current_ap, 0)

	attacker.emit_signal(
		"ap_changed",
		attacker.current_ap,
		attacker.combatant_data.max_ap
	)


# ======================================
# INTERNALS
# ======================================

func _calculate_damage(
	attacker: Combatant,
	target: Combatant,
	attack_data: AttackData
) -> int:

	var atk: int = attacker.combatant_data.attack
	var def: int = target.combatant_data.defense
	var base: int = attack_data.base_power

	var damage: int = base + atk - def

	# Seguridad mínima
	return max(damage, 1)
