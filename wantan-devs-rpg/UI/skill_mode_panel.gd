extends Control
class_name SkillModePanel

signal solo_selected(attack: AttackData)
signal coop_selected(attack: AttackData)
signal back_selected

@onready var overlay: Control = $Overlay
@onready var panel_root: Control = $Overlay/PanelRoot
@onready var attack_name: Label = $Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/AttackName
@onready var attack_question: Label = $Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/AttackQuestion
@onready var solo_button: Button = $Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/Options/SoloButton
@onready var coop_button: Button = $Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/Options/CopButton
@onready var back_button: Button = $Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/BackButton

var current_attack: AttackData
var current_combatant: Combatant


func _ready() -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_gui_input)
	
	solo_button.pressed.connect(_on_solo_button_pressed)
	coop_button.pressed.connect(_on_coop_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func setup(combatant: Combatant, allies: Array[Combatant],attack: AttackData) -> void:
	current_combatant = combatant
	current_attack = attack
	
	attack_name.text = attack.display_name
	attack_question.text = "¿Modo de uso?"
	
	var solo_cost := attack.ap_cost
	var coop_total := int(ceil(attack.ap_cost * attack.coop_ap_multiplier))
	var coop_each := int(coop_total / 2.0)
	
	solo_button.text = "Usar solo (%d AP)" % solo_cost
	coop_button.text = "Usar en equipo (%d AP c/u)" % coop_each
	
	solo_button.disabled = not combatant.can_use_ap(solo_cost)
	
	if attack.coop_ap_multiplier <= 1.0:
		coop_button.disabled = true
	else:
		var any_valid_partner := false
		
		for ally in allies:
			if ally == combatant:
				continue
			if ally.can_use_ap(coop_each):
				any_valid_partner = true
				break
		
		coop_button.disabled = (
			not combatant.can_use_ap(coop_each)
			or not any_valid_partner
		)


func _on_solo_button_pressed() -> void:
	if current_attack == null:
		return
	
	solo_selected.emit(current_attack)
	queue_free()


func _on_coop_button_pressed() -> void:
	if current_attack == null:
		return
	
	coop_selected.emit(current_attack)
	queue_free()


func _on_back_button_pressed() -> void:
	back_selected.emit()
	queue_free()


# =========================
# CLICK FUERA → CERRAR
# =========================
func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var panel_rect: Rect2 = panel_root.get_global_rect()
		
		if not panel_rect.has_point(event.global_position):
			back_selected.emit()
			queue_free()
