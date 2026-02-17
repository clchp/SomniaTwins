extends ColorRect
class_name FadeLayer

func fade_to_black(time := 1.0) -> Tween:
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, time)
	return tween


func fade_from_black(time := 1.0) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.finished.connect(func():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hide()
	)
	return tween
