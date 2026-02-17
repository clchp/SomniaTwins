extends Panel
class_name MainActionPanel

signal fun_pressed
signal bag_pressed
signal skill_pressed
signal attack_pressed

@onready var fun_btn := $HBoxContainer/FUN
@onready var bag_btn := $HBoxContainer/BAG
@onready var skill_btn := $HBoxContainer/SKILL
@onready var attack_btn := $HBoxContainer/ATTACK


func _ready():
	fun_btn.pressed.connect(_on_fun)
	bag_btn.pressed.connect(_on_bag)
	skill_btn.pressed.connect(_on_skill)
	attack_btn.pressed.connect(_on_attack)


func _on_fun():
	fun_pressed.emit()


func _on_bag():
	bag_pressed.emit()


func _on_skill():
	skill_pressed.emit()


func _on_attack():
	attack_pressed.emit()
