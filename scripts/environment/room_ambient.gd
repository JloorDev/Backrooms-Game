extends CanvasModulate

const BASE_COLOR    = Color(0.05, 0.045, 0.04, 1.0)
const FLICKER_COLOR = Color(0.025, 0.022, 0.018, 1.0)

var _flicker: FlickerTimer

func _ready() -> void:
	color = BASE_COLOR
	_flicker = FlickerTimer.new(4.0, 10.0, 0.1, 0.4)

func _process(delta: float) -> void:
	var is_dark_pulse: bool = _flicker.update(delta)
	color = FLICKER_COLOR if is_dark_pulse else BASE_COLOR
