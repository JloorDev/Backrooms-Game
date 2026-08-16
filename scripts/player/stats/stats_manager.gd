extends Node
class_name StatsManager

signal overloaded_changed(is_overloaded: bool)
signal stamina_changed(value: float, percent: float)
signal health_changed(value: float, percent: float)
signal sanity_event(event: SanityEvent)

enum SanityEvent { GHOST_SOUND, LIGHT_FLICKER, HALLUCINATION }

@export var max_stamina:            float = 100.0
@export var max_health:             float = 100.0
@export var stamina_drain_jog:      float = 1.2   # trotar drena poco
@export var stamina_drain_run:      float = 3.5   # correr drena más
@export var stamina_drain_thirst:   float = 0.65
@export var stamina_regen:          float = 2.5
@export var health_drain_thirst:    float = 0.25
@export var overload_speed_penalty: float = 0.30
@export var overload_stamina_mult:  float = 2.0

@onready var hunger:  HungerStat  = $HungerStat
@onready var thirst:  ThirstStat  = $ThirstStat
@onready var sanity:  SanityStat  = $SanityStat
@onready var fatigue: FatigueStat = $FatigueStat

var stamina:       float = 0.0
var health:        float = 0.0
var is_overloaded: bool  = false

var _movement_state: int              = 0
var _inventory:      InventoryManager = null
var _sanity_effects: SanityEffects    = null

func _ready() -> void:
	stamina = max_stamina
	health  = max_health
	thirst.thirst_depleted.connect(_on_thirst_depleted)
	sanity.sanity_threshold_crossed.connect(_on_sanity_threshold_crossed)
	sanity.sanity_changed.connect(_on_sanity_changed_internal)

func _physics_process(delta: float) -> void:
	var is_jogging: bool = _movement_state == 2  # State.JOG
	var is_running: bool = _movement_state == 3  # State.RUN

	hunger.drain(delta, is_running)
	thirst.drain(delta, is_running or is_jogging)
	sanity.drain_passive(delta)

	# Hambre/sed/fatiga afectan cordura
	_update_sanity_from_needs(delta)

	# Pasar porcentajes a fatiga
	fatigue.set_hunger_percent(hunger.get_percent())
	fatigue.set_thirst_percent(thirst.get_percent())
	fatigue.drain(delta, _movement_state)

	_update_stamina(delta, is_jogging, is_running)
	_update_overload()

func set_movement_state(state: int) -> void:
	_movement_state = state

func set_sanity_effects(effects: SanityEffects) -> void:
	_sanity_effects = effects

# ── Puede trotar — stamina > 20% y fatiga no crítica ─────────
func can_jog() -> bool:
	return stamina > max_stamina * 0.20 and fatigue.tier != FatigueStat.FatigueTier.CRITICAL

# ── Puede correr — stamina > 40% y fatiga no crítica ni exhausted ─
func can_run() -> bool:
	return stamina > max_stamina * 0.40 and fatigue.can_sprint()

func set_inventory(inv: InventoryManager) -> void:
	_inventory = inv

func use_consumable(data: ConsumableData) -> void:
	thirst.restore(data.thirst_restore)
	hunger.restore(data.hunger_restore)
	sanity.restore(data.sanity_restore)
	_set_health(health + data.health_restore)
	_set_stamina(stamina + data.stamina_restore)

func use_nostalgia(data: NostalgiaData) -> void:
	sanity.restore(data.sanity_restore)

func get_speed_multiplier() -> float:
	var mult = 1.0
	if is_overloaded:
		mult *= (1.0 - overload_speed_penalty)
	mult *= fatigue.get_speed_penalty()
	if _sanity_effects:
		mult *= _sanity_effects.get_speed_penalty()
	return mult

func get_stamina_drain_multiplier() -> float:
	var mult = overload_stamina_mult if is_overloaded else 1.0
	mult *= fatigue.get_stamina_drain_mult()
	return mult

# ── Stamina según estado de movimiento ───────────────────────
func _update_stamina(delta: float, is_jogging: bool, is_running: bool) -> void:
	if is_running:
		var drain = stamina_drain_run * get_stamina_drain_multiplier()
		_set_stamina(stamina - drain * delta)
	elif is_jogging:
		var drain = stamina_drain_jog * get_stamina_drain_multiplier()
		_set_stamina(stamina - drain * delta)
	elif not thirst.is_empty():
		_set_stamina(stamina + stamina_regen * delta)

func _set_stamina(value: float) -> void:
	stamina = clampf(value, 0.0, max_stamina)
	stamina_changed.emit(stamina, stamina / max_stamina)

# ── Hambre/sed/fatiga drenan cordura ─────────────────────────
func _update_sanity_from_needs(delta: float) -> void:
	var drain: float = 0.0

	match hunger.tier:
		HungerStat.HungerTier.HUNGRY:
			drain += 0.03
		HungerStat.HungerTier.STARVING:
			drain += 0.12

	var thirst_pct = thirst.get_percent()
	if thirst_pct < 0.50:
		drain += lerp(0.0, 0.18, (0.50 - thirst_pct) / 0.50)

	if fatigue.tier == FatigueStat.FatigueTier.CRITICAL:
		drain += 0.08

	if drain > 0.0:
		sanity.drain_from_needs(drain * delta)

func _on_thirst_depleted() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not thirst.is_empty():
		set_process(false)
		return
	if stamina > 0.0:
		_set_stamina(stamina - stamina_drain_thirst * delta)
	else:
		_set_health(health - health_drain_thirst * delta)

func _set_health(value: float) -> void:
	health = clampf(value, 0.0, max_health)
	health_changed.emit(health, health / max_health)

func _update_overload() -> void:
	if _inventory == null:
		return
	var capacity = _inventory.get_max_weight() * hunger.get_carry_multiplier()
	var new_overloaded = _inventory.get_current_weight() > capacity
	if new_overloaded != is_overloaded:
		is_overloaded = new_overloaded
		overloaded_changed.emit(is_overloaded)

func _on_sanity_changed_internal(value: float, percent: float) -> void:
	if _sanity_effects:
		_sanity_effects.on_sanity_changed(value, percent)

func _on_sanity_threshold_crossed(threshold: SanityStat.SanityThreshold) -> void:
	match threshold:
		SanityStat.SanityThreshold.LOW:
			sanity_event.emit(SanityEvent.GHOST_SOUND)
			sanity_event.emit(SanityEvent.LIGHT_FLICKER)
		SanityStat.SanityThreshold.CRITICAL:
			sanity_event.emit(SanityEvent.HALLUCINATION)
