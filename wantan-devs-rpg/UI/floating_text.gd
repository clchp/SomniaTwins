extends Node2D
class_name FloatingText

@onready var label: Label = $Label
@export var move_distance := 20.0
@export var duration := 0.8

func setup(text: String, color: Color):
	label.text = text
	label.modulate = color

	# OUTLINE (contorno)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	animate()


func animate():
	var start_pos = global_position
	var end_pos = global_position + Vector2(0, -move_distance)
	modulate.a = 1.0  # empezar totalmente visible
	var tween = create_tween()
	# movimiento hacia arriba (todo el tiempo)
	tween.tween_property(self, "global_position", end_pos, duration)
	# mantener opacidad la mayor parte del tiempo
	tween.parallel().tween_property(self, "modulate:a", 1.0, duration * 0.4)
	# desvanecer solo al final
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.2)
	tween.finished.connect(queue_free)
