extends Node
class_name PlayerData

var xp: int = 0
var level: int = 1
var gold: int = 0

signal level_up(new_level)

func add_xp(amount: int):
	xp += amount
	check_level_up()

func add_gold(amount: int):
	if amount <= 0:
		return
	gold += amount

# Función para después
func check_level_up():
	var xp_needed := level * 100
	if xp >= xp_needed:
		xp -= xp_needed
		level += 1
		level_up.emit(level)
