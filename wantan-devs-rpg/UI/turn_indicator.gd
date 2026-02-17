extends Node2D
class_name TurnIndicator

@export var size := 5.0
@export var color := Color("8f0c00") # amarillo
@export var float_height := 2.0
@export var float_speed := 2.0

var target: Node2D
var base_offset := Vector2(-5, -38)
var width := size * 1.5
var height := size * 0.7

func _process(_delta):
	if target == null:
		visible = false
		return

	visible = true

	var float_y = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_height
	global_position = target.global_position + base_offset + Vector2(0, float_y)

	queue_redraw()


func _draw():
	# Triángulo apuntando hacia abajo
	var p1 = Vector2(0, height)
	var p2 = Vector2(-width, -height)
	var p3 = Vector2(width, -height)

	draw_polygon([p1, p2, p3], [color])


func attach_to(combatant: Node2D):
	target = combatant
	visible = true


func detach():
	target = null
	visible = false
	
func move_to(target_node: Node2D):
	target = target_node
	visible = true
