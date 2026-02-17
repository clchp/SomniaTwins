extends Control

signal finished(result: QTEResult, multiplier: float)

enum QTEResult {
	PERFECT,
	GOOD,
	MISS
}

@onready var circle: Panel = $CenterContainer/CircleButton
@onready var label: Label = $CenterContainer/CircleButton/Label

var duration: float = 2.0
var time_left: float = 0.0
var presses: int = 0
var active: bool = false

var base_color := Color("#c0392b")
var pressed_color := Color("#922b21")

func start():
	print("=== DEFENSE MASH START ===")
	
	time_left = duration
	presses = 0
	active = true
	
	circle.pivot_offset = circle.size / 2.0
	circle.scale = Vector2.ONE
	_set_circle_color(base_color)


func _process(delta: float) -> void:
	if not active:
		return
		
	time_left -= delta
	
	if time_left <= 0.0:
		_finish()


func _input(event: InputEvent) -> void:
	if not active:
		return
		
	if event.is_action_pressed("action"):
		presses += 1
		_animate_press()


func _animate_press() -> void:
	var original_scale: Vector2 = circle.scale
	
	circle.scale = original_scale * 0.9
	_set_circle_color(pressed_color)
	
	await get_tree().create_timer(0.07).timeout
	
	circle.scale = original_scale
	_set_circle_color(base_color)


func _set_circle_color(color: Color) -> void:
	var style := circle.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = color


func _finish() -> void:
	if not active:
		return
		
	active = false
	
	print("=== DEFENSE MASH END ===")
	print("Total presses:", presses)
	
	var result: QTEResult
	var multiplier: float
	
	if presses >= 12:
		result = QTEResult.PERFECT
		multiplier = 0.4
		
	elif presses >= 6:
		result = QTEResult.GOOD
		multiplier = 0.7
		
	else:
		result = QTEResult.MISS
		multiplier = 1.0
	
	print("Result:", result)
	print("Multiplier:", multiplier)
	
	finished.emit(result, multiplier)
	queue_free()
