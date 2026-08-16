extends Node
class_name ThirstStat

signal thirst_changed(value:float, percent:float)
signal thirst_depleted

@export var max_thirst:float = 100.0
@export var drain_rate:float = 0.08
@export var drain_rate_run:float = 0.14

var current:float = 0.0
var _depleted_emitted:bool = false

func _ready() -> void:
	current = max_thirst

func drain(delta:float, is_running:bool = false) -> void:
	var rate:float = drain_rate_run if is_running else drain_rate
	_set_value(current - rate * delta)

func restore(amount:float) -> void:
	_depleted_emitted = false
	_set_value(current + amount)

func get_percent() -> float:
	return current / max_thirst

func is_empty() -> bool:
	return current <= 0.0

func _set_value(value:float) -> void:
	current = clampf(value, 0.0, max_thirst)
	thirst_changed.emit(current, get_percent())
	if current <= 0.0 and not _depleted_emitted:
		_depleted_emitted = true
		thirst_depleted.emit()
