extends Area2D
class_name NPC

@onready var signo_dialogo = $SignoDialogo
@export var dialogo:String

var is_player_close := false
var player_ref: Player = null

func _process(_delta):
	# Mantener el signo sincronizado con el estado del diálogo
	_update_dialog_icon()

	if not is_player_close:
		return

	if Global.dialogue_active or Global.dialogue_cooldown:
		return

	if Input.is_action_just_pressed("action"):
		start_dialogue()


func _update_dialog_icon():
	# El signo solo aparece si:
	# - el jugador está cerca
	# - no hay diálogo activo
	# - no hay cooldown
	signo_dialogo.visible = (
		is_player_close
		and not Global.dialogue_active
		and not Global.dialogue_cooldown
	)


func start_dialogue():
	Global.dialogue_active = true
	_update_dialog_icon()

	if player_ref:
		player_ref.set_can_move(false)

	Dialogic.start(dialogo)

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_dialogue_finished)


func _on_dialogue_finished():
	Global.dialogue_active = false
	Global.dialogue_cooldown = true

	if player_ref:
		player_ref.set_can_move(true)

	_update_dialog_icon()

	await get_tree().create_timer(0.4).timeout
	Global.dialogue_cooldown = false

	_update_dialog_icon()

	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		is_player_close = true
		_update_dialog_icon()


func _on_body_exited(body):
	if body.is_in_group("player"):
		signo_dialogo.visible = false
		is_player_close = false
		player_ref = null
