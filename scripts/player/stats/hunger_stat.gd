extends Node
class_name HungerStat

signal hunger_changed(value:float, percent:float)
signal tier_changed(tier:HungerTier)

enum HungerTier { SATIATED, HUNGRY, STARVING }

@export var max_hunger:float = 100.0
@export var drain_rate:float = 0.05
@export var drain_rate_run:float = 0.10

var current:float = 0.0
var tier:HungerTier = HungerTier.SATIATED

func _ready() -> void:
	current = max_hunger

func drain(delta:float, is_running:bool = false) -> void:
	var rate:float = drain_rate_run if is_running else drain_rate
	_set_value(current - rate * delta)

func restore(amount:float) -> void:
	_set_value(current + amount)

func get_percent() -> float:
	return current / max_hunger

func get_carry_multiplier() -> float:
	match tier:
		HungerTier.SATIATED : return 1.00
		HungerTier.HUNGRY   : return 0.75
		HungerTier.STARVING : return 0.50
		_                   : return 0.50

func _set_value(value:float) -> void:
	current = clampf(value, 0.0, max_hunger)
	hunger_changed.emit(current, get_percent())
	var new_tier:HungerTier = _compute_tier()
	if new_tier != tier:
		tier = new_tier
		tier_changed.emit(tier)

func _compute_tier() -> HungerTier:
	var pct:float = get_percent()
	if pct > 0.75 : return HungerTier.SATIATED
	if pct > 0.25 : return HungerTier.HUNGRY
	return HungerTier.STARVING
