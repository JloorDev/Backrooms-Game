extends PointLight2D

@export var base_energy: float = 0.95
@export var off_energy:  float = 0.65

@export var broken_light_chance: float = 0.18

@export var effective_radius: float = 46.0

var _flicker: FlickerTimer
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = hash(global_position) ^ randi()
	var is_broken: bool = _rng.randf() < broken_light_chance

	var wait_range: Vector2 = Vector2(1.5, 4.0) if is_broken else Vector2(6.0, 20.0)
	var duration_range: Vector2 = Vector2(0.4, 1.5) if is_broken else Vector2(0.1, 0.4)

	_flicker = FlickerTimer.new(wait_range.x, wait_range.y, duration_range.x, duration_range.y, _rng)
	energy = base_energy

func _process(delta: float) -> void:
	var is_dark_pulse: bool = _flicker.update(delta)
	energy = off_energy if is_dark_pulse else base_energy
