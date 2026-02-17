extends Node
class_name BattleActionExecutor

const DEFENSE_MASH = preload("res://Escenas/Mini-juegos/DefenseMashQTE.tscn")
const CIRCLE = preload("res://Escenas/Mini-juegos/CircleQTE.tscn")
const TIMING_QTE = preload("res://Escenas/Mini-juegos/TimingQTE.tscn")

enum QTEType {
	OFFENSE,
	DEFENSE
}

enum QTEResult {
	PERFECT,
	GOOD,
	MISS
}

func execute_attack(
	attacker: Combatant,
	attack_data: AttackData,
	targets: Array[Combatant],
	damage_multiplier: float = 1.0
) -> void:
	print(">>> EXECUTE_ATTACK START:", attacker.name)
	if attacker == null or attack_data == null:
		push_error("BattleActionExecutor: datos inválidos")
		return

	if targets.is_empty():
		push_warning("BattleActionExecutor: no hay objetivos")
		return

	# consumir AP UNA sola vez
	if not attacker.use_ap(attack_data.ap_cost):
		attacker._spawn_floating_text("NO AP", Color(0.2, 0.6, 1.0))
		print(attacker.name, " no tiene AP suficiente")
		return

	for target in targets:
		if target == null or not target.is_alive:
			continue

		var base_damage := _calculate_damage(attacker, target, attack_data)
		var damage := int(base_damage * damage_multiplier)
		
		print("ANIM TERMINO")
		await target.apply_damage(damage)
		print("%s usa %s sobre %s → %d daño" % [
			attacker.name,
			attack_data.display_name,
			target.name,
			damage
		])
	# Regen solo si es básico
	if attack_data.is_basic:
		attacker.recover_ap(attacker.combatant_data.ap_regen_per_turn)
	
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
	return max(damage, 1)


func execute_item(
	user: Combatant,
	item: ItemData,
	targets: Array[Combatant]
) -> bool:
	if user == null or item == null:
		push_error("Item inválido")
		return false
			
	if targets.is_empty():
		push_warning("Item sin targets válidos")
		return false
		
	var used := false
	
	if item.is_offensive():
		await _play_offensive_item_animation(user, item, targets)
	elif item.is_support():
		await user.play_support_item_animation()

	for target in targets:
		if target == null:
			continue
		
		print("EXEC ITEM START")
		var applied := await _apply_item_effects(user, target, item)
		print("EXEC ITEM END")
		if applied:
			used = true
			
	if used:
		print("%s usa %s" % [user.name, item.display_name])
	
	return used
		

func _apply_item_effects(
	user: Combatant,
	target: Combatant,
	item: ItemData
) -> bool:

	print("EFFECTS ▶ START")

	# REVIVIR
	if _try_revive(item, target):
		return true

	if not target.is_alive:
		return false

	var applied := false

	if await _apply_hp_effects(item, target):
		applied = true
	if _apply_ap_effects(item, target):
		applied = true
	if await _apply_damage_effects(item, target):
		applied = true
	return applied


# HP
func _apply_hp_effects(item: ItemData, target: Combatant) -> bool:
	var applied := false
	var total_heal := 0

	if item.heal_hp_flat > 0 and target.current_hp < target.max_hp:
		total_heal+= item.heal_hp_flat

	if item.heal_hp_percent > 0.0 and target.current_hp < target.max_hp:
		total_heal += int(target.max_hp * item.heal_hp_percent)

	if total_heal > 0:
		target.heal(total_heal)
		await target.play_heal_animation()
		applied = true
		
	return applied


# AP
func _apply_ap_effects(item: ItemData, target: Combatant) -> bool:
	var applied := false

	if item.heal_ap_flat > 0 and target.current_ap < target.max_ap:
		target.recover_ap(item.heal_ap_flat)
		applied = true

	if item.heal_ap_percent > 0.0 and target.current_ap < target.max_ap:
		var amount := int(target.max_ap * item.heal_ap_percent)
		target.recover_ap(amount)
		applied = true

	return applied
	

# DAÑO
func _apply_damage_effects(item: ItemData, target: Combatant) -> bool:
	if item.damage_flat > 0:
		await target.apply_damage(item.damage_flat)
		return true

	if item.damage_percent > 0.0:
		var dmg := int(target.max_hp * item.damage_percent)
		await target.apply_damage(dmg)
		return true
	
	return false


# REVIVIR
func _try_revive(item: ItemData, target: Combatant) -> bool:
	if not item.revive:
		return false

	if target.is_alive:
		return false

	var hp := int(target.max_hp * item.revive_hp_percent)
	target.revive(max(hp, 1))
	return true

# NUEVO
func execute_attack_with_qte(
	attacker: Combatant,
	attack_data: AttackData,
	targets: Array[Combatant]
) -> void:

	# 🟢 JUGADOR ATACANDO → QTE ofensivo global
	if attacker.is_player():
		var multiplier := await _run_qte(QTEType.OFFENSE, attacker)

		await execute_attack(
			attacker,
			attack_data,
			targets,
			multiplier
		)
		return


	# 🔴 ENEMIGO ATACANDO
	if attacker.is_enemy():

		# 🧠 SINGLE TARGET
		if targets.size() == 1:
			var multiplier := await _run_qte(QTEType.DEFENSE, targets[0])

			await execute_attack(
				attacker,
				attack_data,
				targets,
				multiplier
			)
			return


		# 💥 AoE — MULTIPLIER INDIVIDUAL
		for target in targets:
			var multiplier := await _run_qte(QTEType.DEFENSE, target)

			await execute_attack(
				attacker,
				attack_data,
				[target], # se manda individual
				multiplier
			)

		return
func _run_qte(qte_type: int, parent_node: Combatant) -> float:

	var qte_scene: PackedScene
	var position_offset: Vector2
	var scale_value: Vector2 = Vector2.ONE

	match qte_type:
		
		QTEType.OFFENSE:
			qte_scene = TIMING_QTE
			position_offset = Vector2(80, -110)
			scale_value = Vector2(2, 2)

		QTEType.DEFENSE:
			var defense_qtes = [DEFENSE_MASH, CIRCLE]
			qte_scene = defense_qtes.pick_random()
			position_offset = Vector2(200, -100)
			scale_value = Vector2(2, 2)

	var qte = qte_scene.instantiate()
	parent_node.add_child(qte)

	qte.position = position_offset
	qte.scale = scale_value

	qte.start()

	var data = await qte.finished
	var result = data[0]
	var multiplier = data[1]
	
	_show_qte_feedback(result, parent_node)
	
	return multiplier


func _play_offensive_item_animation(user, item, targets):
	
	if user.play_animation("throw"):
		await user.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.2).timeout

func execute_coop_attack(
	attacker1: Combatant,
	attacker2: Combatant,
	attack_data: AttackData,
	target: Combatant
) -> bool:

	if attacker1 == null or attacker2 == null or attack_data == null:
		return false

	var coop_cost := int(ceil(attack_data.ap_cost * attack_data.coop_ap_multiplier))
	var half_cost := int(ceil(coop_cost / 2.0))

	# Verificar AP
	if not attacker1.can_use_ap(half_cost):
		attacker1._spawn_floating_text("NO AP", Color(0.2, 0.6, 1.0))
		print(attacker1.name, " no tiene AP para coop")
		return false

	if not attacker2.can_use_ap(half_cost):
		attacker2._spawn_floating_text("NO AP", Color(0.2, 0.6, 1.0))
		print(attacker2.name, " no tiene AP para coop")
		return false

	# Consumir AP
	attacker1.use_ap(half_cost)
	attacker2.use_ap(half_cost)

	# Animaciones simultáneas
	if attacker1.play_animation(attack_data.id):
		await attacker1.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout
	
	if attacker2.play_animation(attack_data.id):
		await attacker2.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout

	# QTE único
	var multiplier = await _run_qte(QTEType.OFFENSE, attacker1)

	var base1 := _calculate_damage(attacker1, target, attack_data)
	var base2 := _calculate_damage(attacker2, target, attack_data)

	var total_damage := int(
		(base1 + base2) *
		multiplier *
		attack_data.coop_damage_multiplier
	)

	await target.apply_damage(total_damage)

	print("COOP:", attacker1.name, "+", attacker2.name, "→", total_damage)
	return true

func _show_qte_feedback(result: int, parent_node: Combatant) -> void:
	var text := ""
	var color := Color.WHITE

	match result:
		QTEResult.PERFECT:
			text = "PERFECT!"
			color = Color(1.0, 0.9, 0.2) # dorado

		QTEResult.GOOD:
			text = "GOOD"
			color = Color(0.137, 0.416, 0.941, 1.0) # verde

		QTEResult.MISS:
			text = "MISS"
			color = Color(1.0, 0.2, 0.2) # rojo

	var ft = preload("res://UI/FloatingText.tscn").instantiate()
	get_tree().current_scene.add_child(ft)

	ft.global_position = parent_node.global_position + Vector2(0, -60)
	ft.setup(text, color)
