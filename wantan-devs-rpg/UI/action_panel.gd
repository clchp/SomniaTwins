extends PanelContainer
class_name ActionPanel

signal attack_pressed

@onready var attack_button: Button = $VBoxContainer/AttackButton


func _ready():
	hide()
	attack_button.pressed.connect(_on_attack_button_pressed)


func show_panel():
	show()
	attack_button.disabled = false


func hide_panel():
	hide()


func _on_attack_button_pressed():
	attack_button.disabled = true
	emit_signal("attack_pressed")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			queue_free()
