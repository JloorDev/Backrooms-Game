extends Node
class_name PlayerStateManager

signal states_changed(active_states: Array)

enum PlayerState {
	# Hambre
	FULL,           # > 90% — lleno, leve penalización de velocidad
	SATIATED,       # 75-90% — saciado, sin efectos
	PECKISH,        # 50-75% — algo de hambre, sin efectos aún
	HUNGRY,         # 25-50% — hambriento, penalización leve
	VERY_HUNGRY,    # 10-25% — muy hambriento, penalización notable
	STARVING,       # < 10%  — muriendo de hambre

	# Sed
	HYDRATED,       # > 75% — bien hidratado
	THIRSTY,        # 40-75% — algo de sed
	VERY_THIRSTY,   # 15-40% — muy sediento, penalización notable
	DEHYDRATED,     # < 15%  — deshidratado, peligroso

	# Fatiga
	RESTED,         # > 75%
	TIRED,          # 50-75%
	EXHAUSTED,      # 25-50%
	DEAD_TIRED,     # < 25%  — al límite

	# Cordura
	COMPOSED,       # > 75%
	ANXIOUS,        # 50-75%
	DISTRESSED,     # 25-50%
	PANICKING,      # < 25%

	# Stamina
	WINDED,         # < 20% stamina — sin aliento

	# Sobrecarga
	OVERLOADED,     # inventario pesado
}

# Penalizaciones por estado — se acumulan
const STATE_PENALTIES: Dictionary = {
	PlayerState.FULL:         {"speed": -0.05, "stamina_drain": 1.1, "carry": 0.15},
	PlayerState.PECKISH:      {},
	PlayerState.HUNGRY:       {"speed": -0.05, "carry": -0.10, "sanity_drain": 0.03},
	PlayerState.VERY_HUNGRY:  {"speed": -0.15, "carry": -0.25, "stamina_regen": -0.3, "sanity_drain": 0.08},
	PlayerState.STARVING:     {"speed": -0.30, "carry": -0.50, "stamina_regen": -0.6, "sanity_drain": 0.15, "health_drain": 0.05},
	PlayerState.THIRSTY:      {"stamina_regen": -0.1},
	PlayerState.VERY_THIRSTY: {"speed": -0.10, "stamina_regen": -0.4, "sanity_drain": 0.05},
	PlayerState.DEHYDRATED:   {"speed": -0.25, "stamina_regen": -0.8, "sanity_drain": 0.12, "health_drain": 0.10},
	# Nota: TIRED/EXHAUSTED/DEAD_TIRED no llevan "speed" ni "stamina_drain" aquí
	# porque FatigueStat.get_speed_penalty()/get_stamina_drain_mult() ya cubren
	# esa penalización -- ponerla también aquí la aplicaría dos veces.
	PlayerState.TIRED:        {},
	PlayerState.EXHAUSTED:    {"sanity_drain": 0.04},
	PlayerState.DEAD_TIRED:   {"sanity_drain": 0.08, "can_run": false},
	PlayerState.ANXIOUS:      {"sanity_drain": 0.02},
	PlayerState.DISTRESSED:   {"speed": -0.05, "sanity_drain": 0.04, "stamina_drain": 1.1},
	PlayerState.PANICKING:    {"speed": -0.15, "sanity_drain": 0.08, "stamina_drain": 1.3, "input_noise": 0.3},
	PlayerState.WINDED:       {"speed": -0.10, "can_run": false},
	PlayerState.OVERLOADED:   {"speed": -0.30, "stamina_drain": 1.8},
}

# Nombres para mostrar en consola / UI
const STATE_NAMES: Dictionary = {
	PlayerState.FULL:         "Full",
	PlayerState.SATIATED:     "Satiated",
	PlayerState.PECKISH:      "A bit hungry",
	PlayerState.HUNGRY:       "Hungry",
	PlayerState.VERY_HUNGRY:  "Very hungry",
	PlayerState.STARVING:     "Starving",
	PlayerState.HYDRATED:     "Hydrated",
	PlayerState.THIRSTY:      "Thirsty",
	PlayerState.VERY_THIRSTY: "Very thirsty",
	PlayerState.DEHYDRATED:   "Dehydrated",
	PlayerState.RESTED:       "Rested",
	PlayerState.TIRED:        "Tired",
	PlayerState.EXHAUSTED:    "Exhausted",
	PlayerState.DEAD_TIRED:   "Dead tired",
	PlayerState.COMPOSED:     "Composed",
	PlayerState.ANXIOUS:      "Anxious",
	PlayerState.DISTRESSED:   "Distressed",
	PlayerState.PANICKING:    "Panicking",
	PlayerState.WINDED:       "Winded",
	PlayerState.OVERLOADED:   "Overloaded",
}

@onready var stats:StatsManager = $"../StatsManager"

var _active_states:Array[PlayerState] = []
var _last_states:Array[PlayerState] = []
var _check_timer:float = 0.0
const CHECK_INTERVAL:float = 0.5

var _speed_penalty:float = 0.0
var _stamina_drain_mult:float = 1.0
var _stamina_regen_mult:float = 1.0
var _sanity_drain_extra:float = 0.0
var _health_drain_extra:float = 0.0
var _input_noise_mult:float = 0.0
var _carry_bonus:float = 0.0
var _can_run:bool = true
var _can_jog:bool = true

func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0
	_update_states()

func _update_states() -> void:
	_active_states.clear()

	var h_pct = stats.hunger.get_percent()
	var t_pct = stats.thirst.get_percent()
	var f_pct = stats.fatigue.get_percent()
	var s_pct = stats.sanity.get_percent()
	var st_pct = stats.stamina / stats.max_stamina

	# ── Hambre ────────────────────────────
	if   h_pct > 0.90: _active_states.append(PlayerState.FULL)
	elif h_pct > 0.75: _active_states.append(PlayerState.SATIATED)
	elif h_pct > 0.50: _active_states.append(PlayerState.PECKISH)
	elif h_pct > 0.25: _active_states.append(PlayerState.HUNGRY)
	elif h_pct > 0.10: _active_states.append(PlayerState.VERY_HUNGRY)
	else:              _active_states.append(PlayerState.STARVING)

	# ── Sed ───────────────────────────────
	if   t_pct > 0.75: _active_states.append(PlayerState.HYDRATED)
	elif t_pct > 0.40: _active_states.append(PlayerState.THIRSTY)
	elif t_pct > 0.15: _active_states.append(PlayerState.VERY_THIRSTY)
	else:              _active_states.append(PlayerState.DEHYDRATED)

	# ── Fatiga ────────────────────────────
	if   f_pct > 0.75: _active_states.append(PlayerState.RESTED)
	elif f_pct > 0.50: _active_states.append(PlayerState.TIRED)
	elif f_pct > 0.25: _active_states.append(PlayerState.EXHAUSTED)
	else:              _active_states.append(PlayerState.DEAD_TIRED)

	# ── Cordura ───────────────────────────
	if   s_pct > 0.75: _active_states.append(PlayerState.COMPOSED)
	elif s_pct > 0.50: _active_states.append(PlayerState.ANXIOUS)
	elif s_pct > 0.25: _active_states.append(PlayerState.DISTRESSED)
	else:              _active_states.append(PlayerState.PANICKING)

	# ── Stamina ───────────────────────────
	if st_pct < 0.20:
		_active_states.append(PlayerState.WINDED)

	# ── Sobrecarga ────────────────────────
	if stats.is_overloaded:
		_active_states.append(PlayerState.OVERLOADED)

	_compute_penalties()

	if _active_states != _last_states:
		_last_states = _active_states.duplicate()
		states_changed.emit(_active_states)
		_print_states()

func _compute_penalties() -> void:
	_speed_penalty      = 0.0
	_stamina_drain_mult = 1.0
	_stamina_regen_mult = 1.0
	_sanity_drain_extra = 0.0
	_health_drain_extra = 0.0
	_input_noise_mult   = 0.0
	_carry_bonus        = 0.0
	_can_run  = true
	_can_jog  = true

	for state in _active_states:
		if not STATE_PENALTIES.has(state):
			continue
		var p: Dictionary = STATE_PENALTIES[state]
		_speed_penalty      += p.get("speed",         0.0)
		_stamina_drain_mult *= p.get("stamina_drain",  1.0)
		_stamina_regen_mult += p.get("stamina_regen",  0.0)
		_sanity_drain_extra += p.get("sanity_drain",   0.0)
		_health_drain_extra += p.get("health_drain",   0.0)
		_input_noise_mult   += p.get("input_noise",    0.0)
		_carry_bonus        += p.get("carry",          0.0)
		if p.has("can_run") and not p["can_run"]:
			_can_run = false
		if p.has("can_jog") and not p["can_jog"]:
			_can_jog = false

func get_speed_multiplier() -> float:
	return clampf(1.0 + _speed_penalty, 0.2, 1.5)

func get_stamina_drain_mult() -> float:
	return maxf(_stamina_drain_mult, 0.5)

func get_stamina_regen_mult() -> float:
	return clampf(1.0 + _stamina_regen_mult, 0.0, 2.0)

func get_sanity_drain_extra() -> float:
	return _sanity_drain_extra

func get_health_drain_extra() -> float:
	return _health_drain_extra

func get_input_noise_mult() -> float:
	return _input_noise_mult

func get_carry_multiplier() -> float:
	return clampf(1.0 + _carry_bonus, 0.3, 1.3)

func can_run() -> bool:
	return _can_run and stats.can_run()

func can_jog() -> bool:
	return _can_jog and stats.can_jog()

func has_state(s: PlayerState) -> bool:
	return s in _active_states

func get_active_states() -> Array:
	return _active_states

func _print_states() -> void:
	var names: Array = []
	for s in _active_states:
		names.append(STATE_NAMES.get(s, "?"))
	print("[States] ", " | ".join(names))
	print("  Speed: x%.2f | StaDrain: x%.2f | SanDrain: +%.3f" % [
		get_speed_multiplier(),
		get_stamina_drain_mult(),
		get_sanity_drain_extra()
	])
