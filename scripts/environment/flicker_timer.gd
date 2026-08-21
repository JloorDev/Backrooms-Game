class_name FlickerTimer
extends RefCounted

var timer: float = 0.0
var next_flicker: float = 0.0
var in_flicker: bool = false
var flicker_duration: float = 0.0
var flicker_elapsed: float = 0.0

var min_wait: float
var max_wait: float

var min_duration: float
var max_duration: float

var pulse_period: float = 0.08
var pulse_on_ratio: float = 0.5

var _rng: RandomNumberGenerator

func _init(
	p_min_wait: float,
	p_max_wait: float,
	p_min_duration: float,
	p_max_duration: float,
	rng: RandomNumberGenerator = null
) -> void:
	min_wait = p_min_wait
	max_wait = p_max_wait
	min_duration = p_min_duration
	max_duration = p_max_duration
	_rng = rng if rng else RandomNumberGenerator.new()
	_queue_next()


func _queue_next() -> void:
	next_flicker = timer + _rng.randf_range(min_wait, max_wait)

func update(delta: float) -> bool:
	timer += delta

	if in_flicker:
		flicker_elapsed += delta

		if flicker_elapsed >= flicker_duration:
			in_flicker = false
			_queue_next()
			return false

		return fmod(flicker_elapsed, pulse_period) < pulse_period * pulse_on_ratio

	elif timer >= next_flicker:
		in_flicker = true
		flicker_elapsed = 0.0
		flicker_duration = _rng.randf_range(min_duration, max_duration)

	return false
