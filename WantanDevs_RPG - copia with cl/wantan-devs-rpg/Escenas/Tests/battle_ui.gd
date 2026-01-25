extends CanvasLayer
class_name BattleUI

signal action_selected(attack_data)

@onready var action_panel = $ActionPanel

var current_combatant: Combatant

var hermano: Combatant
var hermana: Combatant
var enemigo: Combatant

func _ready():
	action_panel.attack_pressed.connect(_on_attack_pressed)


func show_actions(combatant):
	current_combatant = combatant
	action_panel.show_panel()


func hide_actions():
	action_panel.hide_panel()


func _on_attack_pressed():
	if current_combatant == null:
		return

	var attack = current_combatant.combatant_data.attacks[0]
	hide_actions()
	action_selected.emit(attack)

func bind_combatants(h: Combatant, he: Combatant, e: Combatant):
	hermano = h
	hermana = he
	enemigo = e

	# conectar señales de vida (tdv no conecta bien)
	hermano.hp_changed.connect(_on_hermano_hp_changed)
	hermana.hp_changed.connect(_on_hermana_hp_changed)
	enemigo.hp_changed.connect(_on_enemigo_hp_changed)
	
func _on_hermano_hp_changed(current: int, max_hp: int):
	print("Hermano HP:", current, "/", max_hp)
	# aquí actualizas barra o label

func _on_hermana_hp_changed(current: int, max_hp: int):
	print("Hermana HP:", current, "/", max_hp)

func _on_enemigo_hp_changed(current: int, max_hp: int):
	print("Enemigo HP:", current, "/", max_hp)

func show_result(text: String) -> void:
	print("RESULTADO DE BATALLA:", text)
	hide_actions()
