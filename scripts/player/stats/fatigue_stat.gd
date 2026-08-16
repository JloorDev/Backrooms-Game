extends Node
class_name FatigueStat

signal fatigue_changed(value: float, percent: float)
signal fatigue_tier_changed(tier: FatigueTier)

enum FatigueTier {
	RESTED,      # 75-100% — sin efectos
	TIRED,       # 50-75%  — leve penalización
	EXHAUSTED,   # 25-50%  — penalización notable
	CRITICAL     #  0-25%  — al límite del colapso
}

@export var max_fatigue:     float = 100.0
@export var drain_idle:      float = 0.005   # despierto parado
@export var drain_walk:      float = 0.010   # caminando
@export var drain_run:       float = 0.035   # corriendo
@export var drain_crouch:    float = 0.007   # agachado
@export var regen_rest:      float = 0.08    # descansando (tecla rest)
@export var hunger_mult:     float = 1.4     # hambre aumenta fatiga
@export var thirst_mult:     float = 1.6     # sed aumenta fatiga más

var current:     float = max_fatigue
var tier:        FatigueTier = FatigueTier.RESTED
var is_resting:  bool  = false

# Multiplicadores de hambre/sed pasados desde StatsManager
var _hunger_pct: float = 1.0
var _thirst_pct: float = 1.0

func _ready() -> void:
	current = max_fatigue

func drain(delta: float, movement_state: int) -> void:
	if is_resting:
		_set_value(current + regen_rest * delta)
		return

	# Tasa base según movimiento (usa los valores del enum State de movement.gd)
	# 0=IDLE, 1=WALK, 2=RUN, 3=CROUCH
	var rate: float
	match movement_state:
		2: rate = drain_run
		1: rate = drain_walk
		3: rate = drain_crouch
		_: rate = drain_idle

	# Hambre y sed bajos aumentan la fatiga
	var hunger_factor: float = lerp(hunger_mult, 1.0, _hunger_pct)
	var thirst_factor: float = lerp(thirst_mult, 1.0, _thirst_pct)
	rate *= maxf(hunger_factor, thirst_factor)

	_set_value(current - rate * delta)

func set_hunger_percent(pct: float) -> void:
	_hunger_pct = pct

func set_thirst_percent(pct: float) -> void:
	_thirst_pct = pct

func get_percent() -> float:
	return current / max_fatigue

# Penalización de velocidad según tier (se multiplica en StatsManager)
func get_speed_penalty() -> float:
	match tier:
		FatigueTier.RESTED    : return 1.00
		FatigueTier.TIRED     : return 0.90
		FatigueTier.EXHAUSTED : return 0.75
		FatigueTier.CRITICAL  : return 0.55
		_: return 1.00

# Penalización de stamina drain (más cansado = stamina se agota más rápido)
func get_stamina_drain_mult() -> float:
	match tier:
		FatigueTier.RESTED    : return 1.0
		FatigueTier.TIRED     : return 1.3
		FatigueTier.EXHAUSTED : return 1.7
		FatigueTier.CRITICAL  : return 2.5
		_: return 1.0

# True si el jugador puede correr (CRITICAL bloquea el sprint)
func can_sprint() -> bool:
	return tier != FatigueTier.CRITICAL

func _set_value(value: float) -> void:
	current = clampf(value, 0.0, max_fatigue)
	fatigue_changed.emit(current, get_percent())
	var new_tier = _compute_tier()
	if new_tier != tier:
		tier = new_tier
		fatigue_tier_changed.emit(tier)

func _compute_tier() -> FatigueTier:
	var pct = get_percent()
	if pct > 0.75: return FatigueTier.RESTED
	if pct > 0.50: return FatigueTier.TIRED
	if pct > 0.25: return FatigueTier.EXHAUSTED
	return FatigueTier.CRITICAL
