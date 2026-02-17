extends Node2D
class_name BattleScene

@onready var turn_system: TurnSystem = $TurnSystem
@onready var executor: BattleActionExecutor = $BattleActionExecutor
@onready var player_music = $AudioStreamPlayer

@onready var battle_ui: BattleUI = $BattleUI
const BAG_SELECTION_SCENE = preload("res://UI/BagSelectionPanel.tscn")
const SKILL_SELECTION_SCENE = preload("res://UI/SkillSelectionPanel.tscn")
const SKILL_MODE_SCENE = preload("res://UI/SkillModePanel.tscn")
var current_action_selection: Control = null

@onready var turn_indicator: TurnIndicator = $BattleUI/TurnIndicator
@onready var actor_selector: ActorSelector = $ActorSelector

@onready var main_action_panel: MainActionPanel = $BattleUI/MainActionPanel
@onready var fade_layer: FadeLayer = $BattleUI/FadeRect

var combatants: Array[Combatant] = []
var current_combatant: Combatant

var pending_attack: AttackData
var pending_target: Combatant
var pending_coop_partner: Combatant = null

enum BattleState {
	STARTING_TURN,
	SELECTING_PLAYER,
	SELECTING_ACTION,
	SELECTING_TARGET,
	EXECUTING_ACTION,
	ENDING_TURN,
	BATTLE_FINISHED
}

var battle_state := BattleState.STARTING_TURN

var selection_mode := SelectionMode.NONE

var pending_item: ItemData = null

enum SelectionMode {
	NONE,
	PLAYER,
	ATTACK_TARGET,
	ITEM_TARGET
}

func _ready():
	main_action_panel.fun_pressed.connect(_on_fun)
	main_action_panel.bag_pressed.connect(_on_bag)
	main_action_panel.skill_pressed.connect(_on_skill)
	main_action_panel.attack_pressed.connect(_on_attack)
	
	print("BattleScene READY")
	
	player_music.play()
	
	combatants.clear()
	for child in $Combatant.get_children():
		if child is Combatant:
			combatants.append(child)

	turn_system.turn_started.connect(_on_turn_started)
	battle_ui.action_selected.connect(_on_action_selected)
	battle_ui.bind_combatants(combatants)

	turn_system.setup(combatants)
	turn_system.start()

	battle_ui.hide_actions()
	_force_test_items()
	

# ================================
# TURN FLOW
# ================================
func _on_turn_started(combatant: Combatant) -> void:
	if battle_state == BattleState.BATTLE_FINISHED:
		return

	battle_state = BattleState.STARTING_TURN

	if combatant == null or not combatant.is_alive:
		if not _check_battle_end():
			turn_system.end_turn()
		return

	current_combatant = combatant
	print("\nTurno de:", combatant.name)

	if combatant.combatant_data.is_player:
		turn_indicator.attach_to(combatant)
	else:
		turn_indicator.detach()

	battle_ui.hide_actions()

	if combatant.combatant_data.is_player:
		battle_state = BattleState.SELECTING_PLAYER

		var players: Array[Combatant] = []
		for c in combatants:
			if c.is_alive and c.combatant_data.is_player:
				players.append(c)

		selection_mode = SelectionMode.PLAYER
		
		if actor_selector.actor_selected.is_connected(_on_target_selected):
			actor_selector.actor_selected.disconnect(_on_target_selected)
		
		if actor_selector.actor_selected.is_connected(_on_player_selected):
			actor_selector.actor_selected.disconnect(_on_player_selected)

		actor_selector.setup(players)
		actor_selector.actor_selected.connect(_on_player_selected, CONNECT_ONE_SHOT)
		actor_selector.enable()
	else:
		_execute_enemy_turn(combatant)

func _end_turn_flow():
	battle_ui.set_process_input(true)
	battle_ui.set_process_unhandled_input(true)
	if battle_state == BattleState.ENDING_TURN:
		return

	battle_state = BattleState.ENDING_TURN
	get_viewport().gui_release_focus()
	var battle_ended := _check_battle_end()

	if battle_ended:
		battle_state = BattleState.BATTLE_FINISHED
		return
	# 🔥 SIEMPRE cerrar animaciones
	_reset_combatants_to_idle()

	main_action_panel.hide()
	battle_ui.hide_actions()
	actor_selector.disable()

	turn_system.end_turn()

# ================================
# PLAYER ACTION
# ================================
func _on_action_selected(attack_data: AttackData):
	if battle_state == BattleState.ENDING_TURN or battle_state == BattleState.BATTLE_FINISHED:
		return
		
	if battle_state != BattleState.SELECTING_ACTION:
		return

	if not current_combatant.combatant_data.is_player:
		return

	# 1. Guardar ataque
	pending_attack = attack_data

	# 2. Ocultar UI
	battle_state = BattleState.SELECTING_TARGET
	battle_ui.hide_actions()

	# 3. Activar selector de enemigos
	var enemies := _get_alive_enemies()
	
	actor_selector.disable()
	selection_mode = SelectionMode.ATTACK_TARGET
	actor_selector.setup(enemies)
	
	if actor_selector.actor_selected.is_connected(_on_target_selected):
		actor_selector.actor_selected.disconnect(_on_target_selected)
	actor_selector.actor_selected.connect(_on_target_selected, CONNECT_ONE_SHOT)
	actor_selector.enable()

# ================================
# ENEMY ACTION
# ================================
func _execute_enemy_turn(attacker: Combatant) -> void:
	print("ENEMY TURN START:")
	if not attacker.is_alive:
		return
	# Seguridad por si acaso
	if attacker.combatant_data.is_player:
		return
	var ai_type = attacker.combatant_data.ai_type
	match ai_type:
		CombatantData.AIType.DUMB:
			await _enemy_ai_dumb(attacker)
		CombatantData.AIType.NORMAL:
			await _enemy_ai_normal(attacker)
		CombatantData.AIType.BOSS:
			await _enemy_ai_boss(attacker)

func _enemy_ai_dumb(attacker: Combatant) -> void:
	var possible_targets := _get_targets(attacker)
	if possible_targets.is_empty():
		_end_turn_flow()
		return

	var target: Combatant = possible_targets.pick_random()

	var attacks := attacker.combatant_data.attacks
	if attacks.is_empty():
		_end_turn_flow()
		return

	var attack_data: AttackData
	
	var basic_attacks = _get_basic_attacks(attacker)
	var special_attacks = _get_special_attacks(attacker)
	# 70% básico, 30% skill
	
	if randf() < 0.7 and not basic_attacks.is_empty():
		attack_data = basic_attacks.pick_random()
	elif not special_attacks.is_empty():
		attack_data = special_attacks.pick_random()
	else:
		# fallback si no hay especiales
		attack_data = attacks.pick_random()

	if attacker.play_animation(attack_data.id):
		await attacker.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.25).timeout

	await executor.execute_attack_with_qte(
		attacker,
		attack_data,
		[target]
	)

	_end_turn_flow()
	
func _enemy_ai_normal(attacker: Combatant) -> void:
	# Obtener jugadores vivos
	var possible_targets: Array[Combatant] = _get_targets(attacker)
	if possible_targets.is_empty():
		_end_turn_flow()
		return

	# 🔥 Elegir al más débil
	var target: Combatant = possible_targets[0]
	var lowest_hp_ratio := float(target.current_hp) / target.max_hp

	for t in possible_targets:
		var ratio := float(t.current_hp) / t.max_hp
		if ratio < lowest_hp_ratio:
			target = t
			lowest_hp_ratio = ratio

		# Obtener ataques separados
	var basic_attacks: Array[AttackData] = _get_basic_attacks(attacker)
	var special_attacks: Array[AttackData] = _get_special_attacks(attacker)

	# Si no tiene ataques, terminar turno
	if basic_attacks.is_empty() and special_attacks.is_empty():
		_end_turn_flow()
		return

	var attack_data: AttackData

	# 💀 Si el target está bajo 40% → intentar usar skill
	if lowest_hp_ratio < 0.4 and not special_attacks.is_empty():
		attack_data = special_attacks.pick_random()

	else:
		# ⚖️ Comportamiento normal
		# 60% básico, 40% skill
		if randf() < 0.6 and not basic_attacks.is_empty():
			attack_data = basic_attacks.pick_random()
		elif not special_attacks.is_empty():
			attack_data = special_attacks.pick_random()
		else:
			attack_data = basic_attacks.pick_random()

	if attacker.play_animation(attack_data.id):
		await attacker.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout
		
	await get_tree().create_timer(0.25).timeout

	await executor.execute_attack_with_qte(
		attacker,
		attack_data,
		[target]
	)

	_end_turn_flow()

func _enemy_ai_boss(attacker: Combatant) -> void:
	var possible_targets: Array[Combatant] = _get_targets(attacker)
	if possible_targets.is_empty():
		_end_turn_flow()
		return

	# 🔥 Elegir jugador más débil
	var target: Combatant = possible_targets[0]
	var lowest_hp_ratio := float(target.current_hp) / target.max_hp

	for t in possible_targets:
		var ratio := float(t.current_hp) / t.max_hp
		if ratio < lowest_hp_ratio:
			target = t
			lowest_hp_ratio = ratio

	# Separar ataques
	var basic_attacks: Array[AttackData] = _get_basic_attacks(attacker)
	var special_attacks: Array[AttackData] = _get_special_attacks(attacker)

	if basic_attacks.is_empty() and special_attacks.is_empty():
		_end_turn_flow()
		return

	var attack_data: AttackData
	var boss_hp_ratio := float(attacker.current_hp) / attacker.max_hp

	# =========================
	# 💀 PRIORIDAD 1: REMATAR
	# =========================
	if lowest_hp_ratio < 0.3 and not special_attacks.is_empty():
		attack_data = special_attacks.pick_random()

	# =========================
	# 🔥 PRIORIDAD 2: FASE AGRESIVA
	# =========================
	elif boss_hp_ratio < 0.5:
		# 70% skill, 30% básico
		if randf() < 0.7 and not special_attacks.is_empty():
			attack_data = special_attacks.pick_random()
		elif not basic_attacks.is_empty():
			attack_data = basic_attacks.pick_random()
		else:
			attack_data = special_attacks.pick_random()

	# =========================
	# ⚖️ ESTADO NORMAL
	# =========================
	else:
		# 50% básico, 50% skill
		if randf() < 0.5 and not basic_attacks.is_empty():
			attack_data = basic_attacks.pick_random()
		elif not special_attacks.is_empty():
			attack_data = special_attacks.pick_random()
		else:
			attack_data = basic_attacks.pick_random()

	# =========================
	# 🎯 DETERMINAR TARGETS SEGÚN target_type
	# =========================
	var final_targets: Array[Combatant]

	match attack_data.target_type:
		"single":
			final_targets = [target]

		"all_enemies":
			final_targets = possible_targets

		"self":
			final_targets = [attacker]

		"ally":
			# aliados vivos (excluyendo self si quieres)
			var allies: Array[Combatant] = []
			for c in combatants:
				if c.is_alive and c.combatant_data.is_player == attacker.combatant_data.is_player:
					allies.append(c)
			final_targets = allies

		_:
			final_targets = [target]

	# =========================
	# 🎬 ANIMACIÓN
	# =========================
	if attacker.play_animation(attack_data.id):
		await attacker.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.25).timeout

	# =========================
	# 💥 EJECUTAR ATAQUE
	# =========================
	await executor.execute_attack_with_qte(
		attacker,
		attack_data,
		final_targets
	)

	_end_turn_flow()

func _get_basic_attacks(combatant: Combatant) -> Array[AttackData]:
	var result: Array[AttackData] = []

	for attack in combatant.combatant_data.attacks:
		if attack.is_basic:
			result.append(attack)

	return result

func _get_special_attacks(combatant: Combatant) -> Array[AttackData]:
	var result: Array[AttackData] = []

	for attack in combatant.combatant_data.attacks:
		if attack.is_special:
			result.append(attack)

	return result


# ================================
# BATTLE END
# ================================
func _check_battle_end() -> bool:
	var players_alive := false
	var enemies_alive := false

	for c in combatants:
		if not c.is_alive:
			continue

		if c.combatant_data.is_player:
			players_alive = true
		else:
			enemies_alive = true

	# 🏆 VICTORIA
	if not enemies_alive:
		_handle_victory()
		return true

	# 💀 DERROTA
	if not players_alive:
		_handle_defeat()
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
	var targets: Array[Combatant] = []

	for c in combatants:
		if not c.is_alive:
			continue

		# Solo atacar al equipo contrario
		if attacker.combatant_data.is_player != c.combatant_data.is_player:
			targets.append(c)

	return targets
	
func _get_alive_enemies() -> Array[Combatant]:
	var result: Array[Combatant] = []

	for c in combatants:
		if not c.is_alive:
			continue

		if not c.combatant_data.is_player:
			result.append(c)

	return result

func _on_target_selected(target: Combatant) -> void:
	if battle_state != BattleState.SELECTING_TARGET:
		return

	if pending_item != null:
		_handle_item_target(target)
		return

	if pending_attack != null:
		_handle_attack_target(target)
		return

func _handle_item_target(target: Combatant) -> void:
	battle_state = BattleState.EXECUTING_ACTION
	actor_selector.disable()
	
	var used := await executor.execute_item(current_combatant, pending_item, [target])

	if used:
		Inventory_global.remove_item(pending_item, 1)
		await get_tree().process_frame
		_end_turn_flow()
	else:
		_return_to_action_selection()

	pending_item = null
	
func _handle_attack_target(target: Combatant) -> void:

	pending_target = target

	if not current_combatant.can_use_ap(pending_attack.ap_cost):
		print(current_combatant.name, " no tiene AP suficiente")
		pending_attack = null
		pending_target = null
		return

	battle_state = BattleState.EXECUTING_ACTION
	actor_selector.disable()

	
	if current_combatant.play_animation(pending_attack.id):
		await current_combatant.wait_current_animation()
	else:
		await get_tree().create_timer(0.2).timeout

	await executor.execute_attack_with_qte(
		current_combatant,
		pending_attack,
		[pending_target]
	)

	pending_attack = null
	pending_target = null

	_end_turn_flow()

func _on_player_selected(player: Combatant) -> void:
	if not player.is_alive:
		return
		
	current_combatant = player
	actor_selector.disable()
	battle_state = BattleState.SELECTING_ACTION
	main_action_panel.show()
	# battle_ui.show_actions(player)

# ACCIONES DEL MAIN ACTION PANEL
func _on_fun():
	print("RUN")
	battle_ui.show_result("HAZ HUIDO")
	actor_selector.disable()
	main_action_panel.hide()
	
	# 1. Bloquear inputs
	battle_state = BattleState.BATTLE_FINISHED
	# 2. Fade música
	fade_out_music(1.0)
	# 3. Fade a negro
	var tween := fade_layer.fade_to_black(1.0)
	await tween.finished

	# 4. Cambiar escena
	get_tree().change_scene_to_file("res://Escenas/Tests/test1.tscn")
	# luego: salir de la batalla

func _on_bag():
	print("BAG:", battle_state)

	if battle_state != BattleState.SELECTING_ACTION:
		return

	var inventory := Inventory_global.get_items()
	if inventory.is_empty():
		return

	_open_bag_selection()

func _on_skill():
	print("SKILL:", battle_state)

	if battle_state != BattleState.SELECTING_ACTION:
		return

	if current_combatant == null:
		return

	# Verificar que tenga skills reales
	var has_skills := false
	for attack: AttackData in current_combatant.combatant_data.attacks:
		if not attack.is_basic:
			has_skills = true
			break

	if not has_skills:
		return

	_open_skill_selection()

func _on_attack():
	print("ATTACK")
	battle_ui.show_actions(current_combatant)

func fade_out_music(duration := 1.0) -> void:
	if not player_music.playing:
		return

	var tween = create_tween()
	tween.tween_property(player_music, "volume_db", -40, duration)

func _force_test_items():
	var potion := preload("res://DataCombat/Items/potion_hp.tres")
	var potion_large := preload("res://DataCombat/Items/potion_hp_large.tres")
	var ether := preload("res://DataCombat/Items/ether_ap.tres")
	var antidote := preload("res://DataCombat/Items/antidote.tres")
	var revive := preload("res://DataCombat/Items/revive.tres")
	var bomba := preload("res://DataCombat/Items/bomb.tres")

	Inventory_global.clear()
	Inventory_global.add_item(potion, 5)
	Inventory_global.add_item(potion_large, 2)
	Inventory_global.add_item(ether, 3)
	Inventory_global.add_item(antidote, 1)
	Inventory_global.add_item(revive, 1)
	Inventory_global.add_item(bomba, 1)

func _on_item_selected(item: ItemData) -> void:
	print("ITEM CONFIRMADO:", item.display_name)

	var targets := _get_item_targets(item)

	if targets.is_empty():
		print("No hay objetivos válidos para este item")
		_return_to_action_selection()
		return

	pending_item = item
	main_action_panel.hide()

	if current_action_selection:
		current_action_selection.queue_free()
		current_action_selection = null

	get_viewport().gui_release_focus()

	battle_state = BattleState.SELECTING_TARGET

	# CASO AUTOMÁTICO (1 solo target)
	if targets.size() == 1:
		await _handle_item_target(targets[0])
		return

	# 🔥 CASO CON SELECTOR
	_activate_actor_selector(targets)

func _on_skill_selected(attack: AttackData):
	print("SKILL ELEGIDA:", attack.display_name)

	# Guardar referencia
	pending_attack = attack

	# Cerrar SkillSelectionPanel
	if current_action_selection:
		current_action_selection.queue_free()
		current_action_selection = null

	_open_skill_mode_panel()

func _activate_actor_selector(targets: Array[Combatant]):
	selection_mode = SelectionMode.ITEM_TARGET
	actor_selector.setup(targets)
	if actor_selector.actor_selected.is_connected(_on_target_selected):
		actor_selector.actor_selected.disconnect(_on_target_selected)
	actor_selector.actor_selected.connect(_on_target_selected, CONNECT_ONE_SHOT)
	battle_ui.set_process_input(false)
	battle_ui.set_process_unhandled_input(false)
	await get_tree().process_frame
	actor_selector.enable()
	actor_selector.show()


func _get_item_targets(item: ItemData) -> Array[Combatant]:
	var candidates: Array[Combatant] = []
	for combatant in combatants:
		# --- FLAG FILTER ---
		if combatant == current_combatant:
			if not (item.target_flags & ItemData.ItemTargetFlags.SELF):
				continue
		elif combatant.combatant_data.is_player == current_combatant.combatant_data.is_player:
			if not (item.target_flags & ItemData.ItemTargetFlags.ALLY):
				continue
		else:
			if not (item.target_flags & ItemData.ItemTargetFlags.ENEMY):
				continue
		# --- VALIDATION FILTER ---
		if _is_valid_item_target(item, combatant):
			candidates.append(combatant)

	return candidates

func _return_to_action_selection() -> void:
	print("SE LLAMÓ RETURN_TO_ACTION_SELECTION ELLA")
	pending_item = null
	pending_attack = null
	pending_target = null

	actor_selector.disable() # apagar cualquier selector activo
	battle_state = BattleState.SELECTING_ACTION
	main_action_panel.show()
	
func _on_item_canceled() -> void:
	if battle_state != BattleState.SELECTING_ACTION:
		return
		
	if current_action_selection:
		current_action_selection.queue_free()
		current_action_selection = null
		
	_return_to_action_selection()

func _reset_combatants_to_idle():
	for c in combatants:
		if c != null and c.is_alive:
			c.play_animation("idle")

func _is_valid_item_target(item: ItemData, target: Combatant) -> bool:
	
	# --- REVIVE ---
	if item.revives():
		return not target.is_alive

	# --- HEAL HP ---
	if item.heals_hp():
		if not target.is_alive:
			return false
		return target.current_hp < target.max_hp

	# --- HEAL AP ---
	if item.heals_ap():
		return target.current_ap < target.max_ap

	# --- DAMAGE ---
	if item.damage_flat > 0 or item.damage_percent > 0.0:
		return target.is_alive

	return false

func _open_bag_selection():
	if current_action_selection:
		current_action_selection.queue_free()

	current_action_selection = BAG_SELECTION_SCENE.instantiate()
	battle_ui.add_child(current_action_selection)

	# Posicionarlo encima del jugador actual
	var screen_pos = current_combatant.global_position
	var canvas_pos = battle_ui.get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	current_action_selection.position = canvas_pos + Vector2(-100, -90)

	current_action_selection.option_confirmed.connect(_on_item_selected)
	current_action_selection.canceled.connect(_on_item_canceled)

	current_action_selection.open()

func _open_skill_selection():
	if current_action_selection:
		current_action_selection.queue_free()

	current_action_selection = SKILL_SELECTION_SCENE.instantiate()
	battle_ui.add_child(current_action_selection)

	# Posicionarlo encima del jugador actual
	var screen_pos = current_combatant.global_position
	var canvas_pos = battle_ui.get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	current_action_selection.position = canvas_pos + Vector2(-100, -90)

	current_action_selection.skill_selected.connect(_on_skill_selected)
	current_action_selection.canceled.connect(_on_skill_canceled)

	current_action_selection.open(current_combatant)

	# battle_state = BattleState.SELECTING_ACTION
	

func _on_skill_canceled():
	battle_state = BattleState.SELECTING_ACTION

func _open_skill_mode_panel():
	var skill_mode_panel = SKILL_MODE_SCENE.instantiate()
	battle_ui.add_child(skill_mode_panel)

	# Posicionarlo encima del jugador actual
	var screen_pos = current_combatant.global_position
	var canvas_pos = battle_ui.get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	skill_mode_panel.position = canvas_pos + Vector2(-100, -90)

	var allies: Array[Combatant] = []
	for c in combatants:
		if c.is_alive and c.combatant_data.is_player:
			allies.append(c)
	skill_mode_panel.setup(current_combatant, allies, pending_attack)

	skill_mode_panel.solo_selected.connect(_on_skill_mode_solo)
	skill_mode_panel.coop_selected.connect(_on_skill_mode_coop)
	skill_mode_panel.back_selected.connect(_on_skill_mode_back)

func _on_skill_mode_solo(attack: AttackData):
	print("Modo SOLO seleccionado")

	# Ir directo a seleccionar target
	battle_state = BattleState.SELECTING_TARGET
	main_action_panel.hide()

	var enemies := _get_alive_enemies()

	selection_mode = SelectionMode.ATTACK_TARGET
	actor_selector.setup(enemies)

	if actor_selector.actor_selected.is_connected(_on_target_selected):
		actor_selector.actor_selected.disconnect(_on_target_selected)

	actor_selector.actor_selected.connect(_on_target_selected, CONNECT_ONE_SHOT)
	actor_selector.enable()

func _on_skill_mode_back():
	print("Volver a skills")
	_open_skill_selection()

func _on_skill_mode_coop(attack: AttackData):
	print("Modo COOP seleccionado")

	battle_state = BattleState.SELECTING_TARGET
	main_action_panel.hide()

	# 🔹 Calcular cuánto paga cada uno
	var coop_total := int(ceil(attack.ap_cost * attack.coop_ap_multiplier))
	var coop_each := int(coop_total / 2.0)

	# 1️⃣ Buscar aliados vivos excepto el actual
	var valid_allies: Array[Combatant] = []

	for c in combatants:
		if c.is_alive \
		and c.combatant_data.is_player \
		and c != current_combatant \
		and c.can_use_ap(coop_each):
			valid_allies.append(c)

	# 2️⃣ Si no hay aliados válidos (con AP suficiente)
	if valid_allies.is_empty():
		print("Ningún aliado tiene AP suficiente para coop")
		_return_to_action_selection()
		return

	# 3️⃣ Activar selector solo con aliados válidos
	selection_mode = SelectionMode.PLAYER
	actor_selector.setup(valid_allies)

	# Desconectar conexiones anteriores
	if actor_selector.actor_selected.is_connected(_on_coop_partner_selected):
		actor_selector.actor_selected.disconnect(_on_coop_partner_selected)

	actor_selector.actor_selected.connect(_on_coop_partner_selected, CONNECT_ONE_SHOT)
	actor_selector.enable()

func _on_coop_partner_selected(partner: Combatant) -> void:
	print("Aliado seleccionado:", partner.name)

	pending_coop_partner = partner
	actor_selector.disable()

	# Ahora seleccionar enemigo
	var enemies := _get_alive_enemies()

	selection_mode = SelectionMode.ATTACK_TARGET
	actor_selector.setup(enemies)

	if actor_selector.actor_selected.is_connected(_on_coop_target_selected):
		actor_selector.actor_selected.disconnect(_on_coop_target_selected)

	actor_selector.actor_selected.connect(_on_coop_target_selected, CONNECT_ONE_SHOT)
	actor_selector.enable()
	
func _on_coop_target_selected(target: Combatant) -> void:
	print("Enemigo seleccionado:", target.name)

	battle_state = BattleState.EXECUTING_ACTION
	actor_selector.disable()

	await executor.execute_coop_attack(
		current_combatant,
		pending_coop_partner,
		pending_attack,
		target
	)

	# Limpiar variables
	pending_coop_partner = null
	pending_attack = null

	_end_turn_flow()

## VICTORIA
func _handle_victory() -> void:
	print("VICTORIA")

	battle_state = BattleState.BATTLE_FINISHED

	battle_ui.hide_actions()
	battle_ui.show_result("VICTORIA")

	player_music.stop()

	# Recompensas reales desde enemigos
	var total_xp := 0
	var total_gold := 0

	for c in combatants:
		if c.is_enemy():
			var data := c.combatant_data

			total_xp += data.xp_reward
			total_gold += data.gold_reward

			# Puede no dropear nada
			if randf() <= data.drop_chance:
				var drop := _get_weighted_drop(data.possible_drops)
				
				if drop != null and drop.item != null:
					Inventory_global.add_item(drop.item, 1)
					print("Drop:", drop.item.display_name)

	PlayerData_Global.add_xp(total_xp)
	PlayerData_Global.add_gold(total_gold)

	print("Ganaste ", total_xp, " XP")
	print("Ganaste ", total_gold, " Oro")

	# Animación de celebración
	for c in combatants:
		if c.is_alive and c.combatant_data.is_player:
			if c.play_animation("win"):
				await c.wait_current_animation()
			else:
				await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(2.0).timeout
	
	#Cambiar a escena donde ocurre (provisional)
	get_tree().change_scene_to_file("res://Escenas/Tests/test1.tscn")
	
	
# DERROTA
func _handle_defeat() -> void:
	print("DERROTA")

	battle_state = BattleState.BATTLE_FINISHED

	battle_ui.hide_actions()
	battle_ui.show_result("DERROTA")

	player_music.stop()

	# Aquí no cambiamos escena automático
	# Deja que el UI muestre botón retry
	await get_tree().create_timer(2.0).timeout
	
	#Cambiar a escena donde ocurre (provisional)
	get_tree().change_scene_to_file("res://Escenas/Tests/test1.tscn")


func _get_weighted_drop(drops: Array[DropData]) -> DropData:
	if drops.is_empty():
		return null

	var total_weight := 0.0
	for d in drops:
		total_weight += d.weight

	var roll := randf() * total_weight
	var cumulative := 0.0

	for d in drops:
		cumulative += d.weight
		if roll <= cumulative:
			return d

	return null
