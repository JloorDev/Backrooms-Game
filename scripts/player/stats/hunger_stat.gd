extends Node
class_name HungerStat

signal hunger_changed(value: float, percent: float)

@export var max_hunger: float = 100.0
@export var drain_rate: float = 0.05
@export var drain_rate_run: float = 0.10

var current: float = 0.0

func _ready() -> void:
	current = max_hunger

func drain(delta: float, is_running: bool = false) -> void:
	var rate: float = drain_rate_run if is_running else drain_rate
	_set_value(current - rate * delta)

func restore(amount: float) -> void:
	_set_value(current + amount)

func get_percent() -> float:
	return current / max_hunger

func _set_value(value: float) -> void:
	current = clampf(value, 0.0, max_hunger)
	hunger_changed.emit(current, get_percent())
