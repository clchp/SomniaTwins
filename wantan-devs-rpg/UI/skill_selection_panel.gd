extends Control
class_name SkillSelectionPanel

signal skill_selected(attack: AttackData)
signal canceled

# =========================
# NODES
# =========================
@onready var overlay: Control = $Overlay
@onready var panel_root: Control = $Overlay/PanelRoot

@onready var list_view: Control = $Overlay/PanelRoot/Content/ListView
@onready var info_view: Control = $Overlay/PanelRoot/Content/InfoView

@onready var options_list: VBoxContainer = \
	$Overlay/PanelRoot/Content/ListView/Scroll/OptionsList

@onready var info_name: Label = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/AttackName
@onready var info_description: Label = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/AttackDescription
@onready var back_button: Button = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/BackButton

@onready var button_template: Button = \
	$Overlay/PanelRoot/Content/ListView/Scroll/OptionsList/ItemButtom


var current_combatant: Combatant


# =========================
# READY
# =========================
func _ready() -> void:
	hide()
	_show_list()
	back_button.pressed.connect(_on_back_pressed)
	overlay.gui_input.connect(_on_overlay_input)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# 🔥 IMPORTANTE: ocultar el template real
	button_template.visible = false
	button_template.disabled = true


# =========================
# PUBLIC API
# =========================
func open(combatant: Combatant) -> void:
	current_combatant = combatant
	show()
	_show_list()
	_refresh_skills()


func close() -> void:
	hide()
	clear()
	canceled.emit()


# =========================
# SKILL LIST
# =========================
func _refresh_skills() -> void:
	clear()

	if current_combatant == null:
		return

	for attack: AttackData in current_combatant.combatant_data.attacks:
		if attack.is_basic:
			continue
		
		_add_skill_option(attack)


func _add_skill_option(attack: AttackData) -> void:
	# 🔥 DUPLICATE NORMAL (más estable)
	var btn: Button = button_template.duplicate()
	btn.visible = true
	btn.focus_mode = Control.FOCUS_NONE

	# Asegurar que no herede estado raro
	btn.modulate = Color(1,1,1,1)

	var name_label: Label = btn.get_node("HBoxContainer/LabelName")
	var cost_label: Label = btn.get_node("HBoxContainer/LabelCost")
	
	name_label.text = attack.display_name
	cost_label.text = "%d AP" % attack.ap_cost

	if not current_combatant.can_use_ap(attack.ap_cost):
		btn.disabled = true
		btn.modulate = Color(1,1,1,0.4)

	options_list.add_child(btn)

	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					skill_selected.emit(attack)
				MOUSE_BUTTON_RIGHT:
					_show_info(attack)
	)


# =========================
# INFO VIEW
# =========================
func _show_info(attack: AttackData) -> void:
	list_view.visible = false
	info_view.visible = true

	info_name.text = attack.display_name
	info_description.text = attack.description


func _on_back_pressed() -> void:
	_show_list()


func _show_list() -> void:
	list_view.visible = true
	info_view.visible = false


# =========================
# HELPERS
# =========================
func clear() -> void:
	for child in options_list.get_children():
		if child == button_template:
			continue
		child.queue_free()


# =========================
# CLICK FUERA → CERRAR
# =========================
func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var panel_rect: Rect2 = panel_root.get_global_rect()
		if not panel_rect.has_point(event.global_position):
			close()
