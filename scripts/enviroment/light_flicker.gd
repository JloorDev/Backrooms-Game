extends PointLight2D

@export var base_energy:   float = 0.20
@export var off_energy:    float = 0.08

@export var broken_light_chance: float = 0.18

var _rng := RandomNumberGenerator.new()
var _timer: float = 0.0
var _next_flicker: float = 0.0
var _in_flicker: bool = false
var _flicker_duration: float = 0.0
var _flicker_elapsed: float = 0.0
var _is_broken: bool = false

func _ready() -> void:
	_rng.seed = hash(global_position) ^ randi()
	_is_broken = _rng.randf() < broken_light_chance
	energy = base_energy
	_queue_next_flicker()

func _process(delta: float) -> void:
	_timer += delta

	if _in_flicker:
		_flicker_elapsed += delta

		if fmod(_flicker_elapsed, 0.08) < 0.04:
			energy = off_energy
		else:
			energy = base_energy

		if _flicker_elapsed >= _flicker_duration:
			_in_flicker = false
			energy = base_energy
			_queue_next_flicker()

	elif _timer >= _next_flicker:
		_in_flicker = true
		_flicker_elapsed = 0.0
		_flicker_duration = _rng.randf_range(0.4, 1.5) if _is_broken else _rng.randf_range(0.1, 0.4)

func _queue_next_flicker() -> void:
	if _is_broken:
		_next_flicker = _timer + _rng.randf_range(1.5, 4.0)    # parpadea seguido
	else:
		_next_flicker = _timer + _rng.randf_range(6.0, 20.0)   # parpadea rara vez
