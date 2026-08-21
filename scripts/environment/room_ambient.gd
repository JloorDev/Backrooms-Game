extends CanvasModulate

const BASE_COLOR    = Color(0.04, 0.035, 0.03, 1.0)
const FLICKER_COLOR = Color(0.02, 0.018, 0.015, 1.0)

var _flicker: FlickerTimer

func _ready() -> void:
	color = BASE_COLOR
	_flicker = FlickerTimer.new(4.0, 10.0, 0.1, 0.4)

func _process(delta: float) -> void:
	var is_dark_pulse: bool = _flicker.update(delta)
	color = FLICKER_COLOR if is_dark_pulse else BASE_COLOR
