extends Node
class_name Inventory

signal inventory_updated

# Diccionario: ItemData -> cantidad
var items: Dictionary = {}

func add_item(item: ItemData, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return

	items[item] = items.get(item, 0) + amount
	inventory_updated.emit()

func remove_item(item: ItemData, amount: int = 1) -> void:
	if not items.has(item):
		return

	items[item] -= amount

	if items[item] <= 0:
		items.erase(item)

	inventory_updated.emit()

func get_items() -> Dictionary:
	return items

func has_item(item: ItemData, amount: int = 1) -> bool:
	return items.get(item, 0) >= amount

func clear():
	items.clear()
	inventory_updated.emit()
