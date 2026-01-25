extends Panel

@onready var hp_bar = $HBoxContainer/VBoxContainer/HP/ProgressBar
@onready var hp_label = $HBoxContainer/VBoxContainer/HP/Label

@onready var ap_bar = $HBoxContainer/VBoxContainer/AP/ProgressBar
@onready var ap_label = $HBoxContainer/VBoxContainer/AP/Label

var combatant: Combatant


func bind(_combatant: Combatant) -> void:
	combatant = _combatant

	# conectar señales (una sola vez)
	combatant.hp_changed.connect(_on_hp_changed)
	combatant.ap_changed.connect(_on_ap_changed)

	# pintar estado inicial
	_on_hp_changed(combatant.current_hp, combatant.combatant_data.max_hp)
	_on_ap_changed(combatant.current_ap, combatant.combatant_data.max_ap)


func _on_hp_changed(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = "HP %d/%d" % [current, max_hp]


func _on_ap_changed(current: int, max_ap: int) -> void:
	ap_bar.max_value = max_ap
	ap_bar.value = current
	ap_label.text = "AP %d/%d" % [current, max_ap]
