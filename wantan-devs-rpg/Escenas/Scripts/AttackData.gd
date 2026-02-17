extends Resource
class_name AttackData

# =========================
# IDENTIDAD
# =========================
@export var id: String
@export var display_name: String
@export var description: String

# =========================
# COSTOS
# =========================
@export var ap_cost: int = 0

# =========================
# TIPO DE ATAQUE
# =========================
@export var is_basic: bool = false
@export var is_special: bool = false
@export var is_coop: bool = false

# =========================
# TARGETING
# =========================
@export var target_type: String = "single"
# single | all_enemies | self | ally

@export var can_target_self: bool = false

# =========================
# DAÑO
# =========================
@export var base_power: int = 10
@export var damage_type: String = "physical"
# physical | elemental

@export var element: String = "none"
# none | fire | ice | electric

# =========================
# REGLAS ESPECIALES
# =========================
@export var requires_coop_partner: bool = false
@export var coop_partner_id: String = ""

@export var can_be_used_solo: bool = true
@export var can_be_used_coop: bool = false

@export var coop_ap_multiplier: float = 1.4
@export var coop_damage_multiplier: float = 1.4
# =========================
# EFECTOS (FUTURO)
# =========================
@export var status_effects: Array[String] = []
