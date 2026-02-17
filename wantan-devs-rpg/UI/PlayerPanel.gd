extends Panel
class_name PlayerPanel

@onready var portrait = $HBoxContainer/TextureRect

@onready var hp_bar = $HBoxContainer/VBoxContainer/HP/ProgressBar
@onready var hp_label = $HBoxContainer/VBoxContainer/HP/Label

@onready var ap_container = $HBoxContainer/VBoxContainer/AP
@onready var ap_bar = $HBoxContainer/VBoxContainer/AP/ProgressBar
@onready var ap_label = $HBoxContainer/VBoxContainer/AP/Label

var combatant: Combatant
var is_enemy := false
var hp_tween: Tween
var ap_tween: Tween


func bind(_combatant: Combatant) -> void:
	if combatant:
		if combatant.hp_changed.is_connected(_on_hp_changed):
			combatant.hp_changed.disconnect(_on_hp_changed)
		if combatant.ap_changed.is_connected(_on_ap_changed):
			combatant.ap_changed.disconnect(_on_ap_changed)

	combatant = _combatant
	
	combatant.hp_changed.connect(_on_hp_changed)
	combatant.ap_changed.connect(_on_ap_changed)

	_on_hp_changed(combatant.current_hp, combatant.max_hp)
	_on_ap_changed(combatant.current_ap, combatant.max_ap)


func _on_hp_changed(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp

	if hp_tween:
		hp_tween.kill()

	hp_tween = hp_bar.create_tween()
	hp_tween.tween_property(hp_bar, "value", current, 0.2)

	hp_label.text = "HP %d/%d" % [current, max_hp]


func _on_ap_changed(current: int, max_ap: int) -> void:
	ap_bar.max_value = max_ap

	if ap_tween:
		ap_tween.kill()

	ap_tween = ap_bar.create_tween()
	ap_tween.tween_property(ap_bar, "value", current, 0.15)

	ap_label.text = "AP %d/%d" % [current, max_ap]
	
######################################################
func _set_hp_color(color: Color) -> void:
	var base_style: StyleBox = hp_bar.get_theme_stylebox("fill")
	var style: StyleBoxFlat

	if base_style is StyleBoxFlat:
		style = base_style.duplicate()
	else:
		style = StyleBoxFlat.new()

	style.bg_color = color
	hp_bar.add_theme_stylebox_override("fill", style)
	

func setup_as_enemy():
	is_enemy = true
	# ocultar portrait
	portrait.visible = false
	# ocultar AP completo
	ap_container.visible = false
	_set_hp_color(Color(0.8, 0.2, 0.2)) # rojo enemigo
	
func setup_as_player():
	is_enemy = false

	portrait.visible = true
	ap_container.visible = true
	_set_hp_color(Color(0.4, 0.9, 0.4)) # verde jugador
	
