extends CanvasModulate

const BASE_COLOR    = Color(0.04, 0.035, 0.03, 1.0)
const FLICKER_COLOR = Color(0.02, 0.018, 0.015, 1.0)

var _timer: float       = 0.0
var _next_flicker: float = 0.0
var _in_flicker: bool   = false
var _flicker_duration: float = 0.0
var _flicker_elapsed: float  = 0.0

func _ready() -> void:
	color = BASE_COLOR
	_next_flicker = randf_range(4.0, 10.0)

func _process(delta: float) -> void:
	_timer += delta

	if _in_flicker:
		_flicker_elapsed += delta

		if fmod(_flicker_elapsed, 0.08) < 0.04:
			color = FLICKER_COLOR
		else:
			color = BASE_COLOR

		if _flicker_elapsed >= _flicker_duration:
			_in_flicker = false
			color = BASE_COLOR
			_next_flicker = _timer + randf_range(5.0, 15.0)

	elif _timer >= _next_flicker:
		_in_flicker = true
		_flicker_elapsed = 0.0
		_flicker_duration = randf_range(0.1, 0.4)
