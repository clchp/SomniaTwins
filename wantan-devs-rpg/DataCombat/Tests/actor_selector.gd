extends Node2D
class_name ActorSelector

signal actor_selected(combatant: Combatant)

@export var turn_indicator: TurnIndicator

var actors: Array[Combatant] = []
var index := 0
var active := false


func _ready():
	set_process_input(true)
	set_process_unhandled_input(true)
# =========================
# SETUP
# =========================
func setup(_actors: Array[Combatant]) -> void:
	actors = _actors
	index = 0
	_update_indicator()

func disable() -> void:
	active = false
	if turn_indicator:
		turn_indicator.hide()


# =========================
# INPUT
# =========================
func _unhandled_input(event):
	if not active:
		return

	if event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		_confirm()


func _confirm():
	if actors.is_empty():
		return

	active = false
	actor_selected.emit(actors[index])


func _move(dir: int):
	if actors.is_empty():
		return

	index += dir
	if index < 0:
		index = actors.size() - 1
	elif index >= actors.size():
		index = 0

	_update_indicator()


# =========================
# VISUAL
# =========================
func _update_indicator():
	if not turn_indicator or actors.is_empty():
		return

	turn_indicator.move_to(actors[index])

# =========================
# PUBLIC
# =========================
func get_selected_actor() -> Combatant:
	if actors.is_empty():
		return null
	return actors[index]

func enable() -> void:
	active = true
	if turn_indicator:
		turn_indicator.show()
