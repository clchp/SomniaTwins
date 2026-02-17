extends Node
class_name GameState

# Verificar si está el jugador en un dialogo
var dialogue_active: bool = false
var dialogue_cooldown: bool = false

# Verificar si está en combate
var in_combat: bool = false

# Inventario
var inventory: Dictionary = {}
# ejemplo:
# inventory = {
#   "potion": 3,
#   "ether": 1
# }

# Equipo de los personajes en combate
var party: Array[String] = ["hermana"] # ids de personajes

# Funciones para el inventario
func add_item(item_id: String, amount: int = 1):
	if inventory.has(item_id):
		inventory[item_id] += amount
	else:
		inventory[item_id] = amount

func remove_item(item_id: String, amount: int = 1):
	if !inventory.has(item_id):
		return
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.has(item_id) and inventory[item_id] >= amount
