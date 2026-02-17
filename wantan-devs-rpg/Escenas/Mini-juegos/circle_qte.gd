extends Control

enum QTEResult {
	PERFECT,
	GOOD,
	MISS
}

signal finished(result: QTEResult, multiplier: float)

@onready var moving_ring: Panel = $CenterContainer/CircleContainer/MovingRing
@onready var perfect_zone: Panel = $CenterContainer/CircleContainer/PerfectZone
@onready var press_text: Label = $CenterContainer/CircleContainer/PressText

var active := false

var duration := 1.5
var time_left := 0.0

var start_size := 216.0
var perfect_size := 60.0
var perfect_tolerance := 10.0
var good_tolerance := 25.0

func start():
	print("=== CIRCLE QTE START ===")
	
	time_left = duration
	active = true
	
	moving_ring.scale = Vector2.ONE
	moving_ring.pivot_offset = moving_ring.size / 2.0
	

func _process(delta):
	if not active:
		return
	
	time_left -= delta
	
	var progress := 1.0 - (time_left / duration)
	progress = clamp(progress, 0.0, 1.0)
	
	var new_scale := 1.0 - progress
	moving_ring.scale = Vector2.ONE * new_scale
	
	if time_left <= 0:
		_finish(QTEResult.MISS, 1.0)


func _input(event):
	if not active:
		return
	
	if event.is_action_pressed("action"):
		
		var current_size := start_size * moving_ring.scale.x
		var difference: float = abs(current_size - perfect_size)
		
		print("Pressed at size:", current_size)
		print("Difference from perfect:", difference)
		
		if difference <= perfect_tolerance:
			_finish(QTEResult.PERFECT, 0.4)
			
		elif difference <= good_tolerance:
			_finish(QTEResult.GOOD, 0.7)
			
		else:
			_finish(QTEResult.MISS, 1.0)


func _finish(result: QTEResult, multiplier: float):
	if not active:
		return
	
	active = false
	
	print("=== CIRCLE QTE END ===")
	print("Result:", result)
	print("Multiplier:", multiplier)
	
	finished.emit(result, multiplier)
	queue_free()
