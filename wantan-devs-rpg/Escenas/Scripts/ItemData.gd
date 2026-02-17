extends Resource
class_name ItemData

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export var item_type: ItemType = ItemType.CONSUMABLE
@export_flags("SELF", "ALLY", "ENEMY")
var target_flags : int = ItemTargetFlags.SELF

@export var usable_in_battle := true
@export var usable_in_exploration := false

@export var max_stack := 99

# =========================
# EFFECT DATA
# =========================
@export var heal_hp_flat := 0
@export var heal_hp_percent := 0.0   # 0.4 = 40%

@export var heal_ap_flat := 0
@export var heal_ap_percent := 0.0

@export var revive := false
@export var revive_hp_percent := 0.0 # 0.4 = 40%

@export var damage_flat := 0
@export var damage_percent := 0.0

enum ItemType {
	CONSUMABLE,
	KEY,
	EQUIPMENT
}

enum ItemTargetFlags {
	SELF   = 1,
	ALLY   = 2,
	ENEMY  = 4
}
func heals_hp() -> bool:
	return heal_hp_flat > 0 or heal_hp_percent > 0.0

func heals_ap() -> bool:
	return heal_ap_flat > 0 or heal_ap_percent > 0.0

func revives() -> bool:
	return revive
	
func is_offensive() -> bool:
	return damage_flat > 0 or damage_percent > 0.0

func is_support() -> bool:
	return heals_hp() or heals_ap() or revives()
