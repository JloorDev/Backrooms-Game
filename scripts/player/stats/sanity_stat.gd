extends Node
class_name SanityStat

signal sanity_changed(value: float, percent: float)
signal sanity_threshold_crossed(threshold: SanityThreshold)

enum SanityThreshold { NORMAL, LOW, CRITICAL }

@export var max_sanity:    float = 100.0
@export var passive_drain: float = 0.25
@export var dark_drain:    float = 0.20
@export var entity_drain:  float = 0.65

@export var light_restore: float = 0.12

var current:   float           = max_sanity
var threshold: SanityThreshold = SanityThreshold.NORMAL

var _in_darkness: bool = false
var _near_entity: bool = false

func _ready() -> void:
	current = max_sanity

func drain_passive(delta: float) -> void:
	if _in_darkness:
		var rate: float = passive_drain + dark_drain
		if _near_entity: rate += entity_drain
		_set_value(current - rate * delta)
	else:
		var rate: float = 0.0
		if _near_entity: rate += entity_drain
		var net: float = light_restore - rate
		_set_value(current + net * delta)

# Drain separado por hambre/sed/fatiga
func drain_from_needs(amount: float) -> void:
	_set_value(current - amount)

func restore(amount: float) -> void:
	_set_value(current + amount)

func set_in_darkness(value: bool) -> void:
	_in_darkness = value

func set_near_entity(value: bool) -> void:
	_near_entity = value

func get_percent() -> float:
	return current / max_sanity

func _set_value(value: float) -> void:
	current = clampf(value, 0.0, max_sanity)
	sanity_changed.emit(current, get_percent())
	var new_threshold = _compute_threshold()
	if new_threshold != threshold:
		threshold = new_threshold
		sanity_threshold_crossed.emit(threshold)

func _compute_threshold() -> SanityThreshold:
	var pct = get_percent()
	if pct > 0.50: return SanityThreshold.NORMAL
	if pct > 0.25: return SanityThreshold.LOW
	return SanityThreshold.CRITICAL
