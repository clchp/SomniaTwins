extends Resource
class_name CombatantData

# =========================
# IDENTIDAD
# =========================
@export var id: String
@export var display_name: String

# =========================
# TIPO DE COMBATIENTE
# =========================
@export var is_player: bool = false
@export var is_boss: bool = false

# =========================
# STATS BASE
# =========================
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10

# =========================
# RECURSOS DE COMBATE
# =========================
@export var max_ap: int = 3
@export var ap_regen_per_turn: int = 1

# =========================
# ATAQUES
# =========================
# Lista de AttackData (.tres)
@export var attacks: Array[AttackData] = []

# =========================
# COOPERATIVO
# =========================
@export var can_coop_attacks: bool = false
@export var coop_partner_id: String = "" 
# Ej: "hermano" / vacío si no aplica

# =========================
# ELEMENTOS (simple y flexible)
# =========================
@export var elemental_affinity: String = "none"
# Ej: none, fire, ice, electric

@export var elemental_resistances: Dictionary = {
	"fire": 1.0,
	"ice": 1.0,
	"electric": 1.0
}
# 1.0 = daño normal
# <1.0 = resiste
# >1.0 = débil

# =========================
# REFERENCIAS VISUALES (SOLO DATA)
# =========================
@export var battle_scene: PackedScene
@export var portrait: Texture2D
