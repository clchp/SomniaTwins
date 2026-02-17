extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player = $AnimationPlayer

signal on_transition_finished

func _ready():
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "fade_to_black":
		#wbds de nombres q ponia por estar en la madrugada, no hacer caso a eso
		on_transition_finished.emit()
		animation_player.play("black_to_fade")
	elif anim_name == "black_to_fade": 
		color_rect.visible = false
		
func transition():
	color_rect.visible = true
	animation_player.play("fade_to_black")
