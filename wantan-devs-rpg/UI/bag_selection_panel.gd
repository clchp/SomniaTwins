extends Control
class_name BagSelectionPanel

signal option_confirmed(data)
signal canceled
# =========================
# NODES
# =========================
@onready var overlay: Control = $Overlay
@onready var panel_root: Control = $Overlay/PanelRoot

@onready var list_view: Control = $Overlay/PanelRoot/Content/ListView
@onready var info_view: Control = $Overlay/PanelRoot/Content/InfoView

@onready var options_list: VBoxContainer = \
	$Overlay/PanelRoot/Content/ListView/Scroll/OptionsList

@onready var info_name: Label = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/ItemName
@onready var info_description: Label = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/ItemDescription
@onready var back_button: Button = \
	$Overlay/PanelRoot/Content/InfoView/MarginContainer/InfoContent/BackButton

@onready var item_button_template: Button = \
	$Overlay/PanelRoot/Content/ListView/Scroll/OptionsList/ItemButtom

# =========================
# READY
# =========================
func _ready() -> void:
	hide()
	_show_list()
	Inventory_global.inventory_updated.connect(_refresh_inventory)
	back_button.pressed.connect(_on_back_pressed)
	overlay.gui_input.connect(_on_overlay_input)
	
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

# =========================
# PUBLIC API
# =========================
## options: Array de cualquier data (ItemData, SkillData, AttackData, etc)
## count_map: Dictionary opcional { data -> cantidad }
func open() -> void:
	show()
	_show_list()
	_refresh_inventory()

func close() -> void:
	hide()
	clear()
	canceled.emit()


# =========================
# OPTIONS
# =========================
func _add_option(item: ItemData, count: int) -> void:
	var btn: Button = item_button_template.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
	btn.visible = true
	btn.focus_mode = Control.FOCUS_NONE

	# Obtener labels
	var name_label: Label = btn.get_node("HBoxContainer/LabelName")
	var count_label: Label = btn.get_node("HBoxContainer/LabelCount")

	name_label.text = item.display_name
	count_label.text = "x%d" % count

	options_list.add_child(btn)

	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					print("OBJETO A USAR:", item.display_name)
					emit_signal("option_confirmed", item)
					close()

				MOUSE_BUTTON_RIGHT:
					_show_info(item)
	)

# =========================
# INFO VIEW
# =========================
func _show_info(data) -> void:
	list_view.visible = false
	info_view.visible = true

	if data is ItemData:
		info_name.text = data.display_name
		info_description.text = data.description
	else:
		info_name.text = ""
		info_description.text = ""

func _on_back_pressed() -> void:
	_show_list()


func _show_list() -> void:
	list_view.visible = true
	info_view.visible = false


# =========================
# HELPERS
# =========================
func clear():
	for child in options_list.get_children():
		if child == item_button_template:
			continue
		child.queue_free()


# =========================
# CLICK FUERA → CERRAR
# =========================
func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var panel_rect: Rect2 = panel_root.get_global_rect()
		if not panel_rect.has_point(event.global_position):
			close()

func _refresh_inventory() -> void:
	if not visible:
		return

	clear()

	var items := Inventory_global.get_items()
	for item: ItemData in items.keys():
		var count: int = items[item]
		_add_option(item, count)

	# si ya no hay ítems → cerrar panel
	if items.is_empty():
		close()
