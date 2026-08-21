extends Node
class_name StatsManager

signal overloaded_changed(is_overloaded: bool)
signal stamina_changed(value: float, percent: float)
signal health_changed(value: float, percent: float)
signal sanity_event(event: SanityEvent)

enum SanityEvent { GHOST_SOUND, LIGHT_FLICKER, HALLUCINATION }

@export var max_stamina:            float = 100.0
@export var max_health:             float = 100.0
@export var stamina_drain_jog:      float = 1.2
@export var stamina_drain_run:      float = 3.5
@export var stamina_drain_thirst:   float = 0.65
@export var stamina_regen:          float = 2.5
@export var health_drain_thirst:    float = 0.25
@export var overload_speed_penalty: float = 0.30
@export var overload_stamina_mult:  float = 2.0

@export var run_threshold: float = 0.40

@onready var hunger:  HungerStat  = $HungerStat
@onready var thirst:  ThirstStat  = $ThirstStat
@onready var sanity:  SanityStat  = $SanityStat
@onready var fatigue: FatigueStat = $FatigueStat
@onready var psm: PlayerStateManager = get_parent().get_node("PlayerStateManager")

var stamina:       float = 0.0
var health:        float = 0.0
var is_overloaded: bool  = false

var _movement_state: int              = 0
var _inventory:      InventoryManager = null
var _sanity_effects: SanityEffects    = null

var _run_locked: bool = false
var _fully_exhausted: bool = false

func _ready() -> void:
	stamina = max_stamina
	health  = max_health
	thirst.thirst_depleted.connect(_on_thirst_depleted)
	sanity.sanity_threshold_crossed.connect(_on_sanity_threshold_crossed)
	sanity.sanity_changed.connect(_on_sanity_changed_internal)

func _physics_process(delta: float) -> void:
	var is_jogging: bool = _movement_state == PlayerMovement.State.JOG
	var is_running: bool = _movement_state == PlayerMovement.State.RUN

	hunger.drain(delta, is_running)
	thirst.drain(delta, is_running or is_jogging)

	_update_light_exposure()
	sanity.drain_passive(delta)

	# Hambre/sed/fatiga/cordura ya se combinan en PlayerStateManager --
	# una sola fuente de verdad, sin recalcular umbrales aquí de nuevo.
	sanity.drain_from_needs(psm.get_sanity_drain_extra() * delta)

	# Pass percentages down to fatigue
	fatigue.set_hunger_percent(hunger.get_percent())
	fatigue.set_thirst_percent(thirst.get_percent())
	fatigue.drain(delta, _movement_state)

	_update_stamina(delta, is_jogging, is_running)
	_update_overload()

func set_movement_state(state: int) -> void:
	_movement_state = state

func set_sanity_effects(effects: SanityEffects) -> void:
	_sanity_effects = effects

func can_jog() -> bool:
	return not _fully_exhausted and stamina > 0.0 and fatigue.tier != FatigueStat.FatigueTier.CRITICAL

func can_run() -> bool:
	return not _run_locked and not _fully_exhausted and fatigue.can_sprint()

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

func _update_stamina(delta: float, is_jogging: bool, is_running: bool) -> void:
	if is_running:
		var drain = stamina_drain_run * get_stamina_drain_multiplier()
		_set_stamina(stamina - drain * delta)
	elif is_jogging:
		var drain = stamina_drain_jog * get_stamina_drain_multiplier()
		_set_stamina(stamina - drain * delta)
	elif not thirst.is_empty():
		_set_stamina(stamina + stamina_regen * delta)

	var pct: float = stamina / max_stamina

	if stamina <= 0.0:
		_fully_exhausted = true
		_run_locked = true
	elif pct < run_threshold:
		_run_locked = true

	if pct >= 1.0:
		_fully_exhausted = false
		_run_locked = false

func _set_stamina(value: float) -> void:
	stamina = clampf(value, 0.0, max_stamina)
	stamina_changed.emit(stamina, stamina / max_stamina)

func _update_light_exposure() -> void:
	var player_pos: Vector2 = get_parent().global_position
	var in_light: bool = false

	for l in get_tree().get_nodes_in_group("dynamic_lights"):
		if not (l is PointLight2D) or not l.visible or l.energy <= 0.02:
			continue
		var radius = l.get("effective_radius")
		if radius == null:
			radius = 46.0
		if player_pos.distance_to(l.global_position) <= radius:
			in_light = true
			break

	sanity.set_in_darkness(not in_light)

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
	var capacity = _inventory.get_max_weight() * psm.get_carry_multiplier()
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
