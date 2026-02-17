extends Control

signal finished(result: QTEResult, multiplier: float)

enum QTEResult {
	PERFECT,
	GOOD,
	MISS
}

@onready var indicator: Panel = $Indicator
@onready var bar: ProgressBar = $Bar
@onready var timer: Timer = $Timer

var speed := 200.0
var direction := 1
var active := false

var perfect_min := 40
var perfect_max := 60

func _ready() -> void:
	start()

func start():
	print("=== TIMING QTE START ===")
	
	# Reset state
	bar.value = 0
	direction = 1
	active = true
	
	# Timer config
	timer.stop()
	timer.wait_time = 2.0
	timer.one_shot = true
	
	# Prevent double connections
	if not timer.timeout.is_connected(_on_Timer_timeout):
		timer.timeout.connect(_on_Timer_timeout)
	
	timer.start()


func _process(delta):
	if not active:
		return
	
	bar.value += speed * direction * delta
	
	if bar.value >= bar.max_value:
		bar.value = bar.max_value
		direction = -1
	elif bar.value <= 0:
		bar.value = 0
		direction = 1
	
	_update_indicator_position()


func _input(event):
	if not active:
		return

	if event.is_action_pressed("action"):
		_check_timing()


func _check_timing():
	active = false
	timer.stop()

	var result: QTEResult
	var multiplier: float

	if bar.value >= perfect_min and bar.value <= perfect_max:
		result = QTEResult.PERFECT
		multiplier = 1.5
		
	else:
		result = QTEResult.MISS
		multiplier = 1.0

	print("Result:", result)
	print("Multiplier:", multiplier)

	finished.emit(result, multiplier)
	queue_free()


func _on_Timer_timeout():
	if not active:
		return
		
	active = false
	
	print("TIME OUT")
	finished.emit(QTEResult.MISS, 1.0)
	queue_free()


func _update_indicator_position():
	var ratio: float = bar.value / bar.max_value
	var bar_width: float = bar.size.x
	
	indicator.position.x = bar.position.x + (bar_width * ratio) - indicator.size.x / 2
	indicator.position.y = bar.position.y
