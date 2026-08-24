extends Camera2D

@export var max_offset:float = 130.0
@export var dead_zone:float = 40.0
@export var lerp_speed:float = 6.0
@export var lock_lerp:float = 12.0

@export var zoom_step:Vector2 = Vector2(0.25, 0.25)
@export var zoom_min:Vector2 = Vector2(2, 2)
@export var zoom_max:Vector2 = Vector2(6.5, 6.5)
@export var zoom_default:Vector2 = Vector2(5, 5)
@export var zoom_lerp:float = 15.0

@export var level_bounds: Rect2 = Rect2()

@onready var player:CharacterBody2D = get_parent()

var cam_locked:bool = true
var target_zoom:Vector2 = Vector2.ONE

var _ambient_shake: float = 0.0
var _burst_shake: float = 0.0
var _shake_timer: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = false
	top_level = true
	target_zoom = zoom_default
	zoom = zoom_default
	global_position = player.global_position
	_apply_level_bounds()

func set_level_bounds(bounds: Rect2) -> void:
	level_bounds = bounds
	_apply_level_bounds()

func _apply_level_bounds() -> void:
	if level_bounds.size == Vector2.ZERO:
		limit_left = -10000000
		limit_top = -10000000
		limit_right = 10000000
		limit_bottom = 10000000
		return
	limit_left = int(level_bounds.position.x)
	limit_top = int(level_bounds.position.y)
	limit_right = int(level_bounds.end.x)
	limit_bottom = int(level_bounds.end.y)

func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("camera_lock"):
		cam_locked = !cam_locked

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = (target_zoom + zoom_step).clamp(zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = (target_zoom - zoom_step).clamp(zoom_min, zoom_max)

func _physics_process(delta:float) -> void:
	var zoom_t: float = 1.0 - pow(2.0, -zoom_lerp * delta)
	zoom = zoom.lerp(target_zoom, zoom_t)

	var target:Vector2

	if cam_locked:
		target = player.global_position
		var t: float = 1.0 - pow(2.0, -lock_lerp * delta)
		global_position = global_position.lerp(target, t)
	else:
		target = player.global_position + _get_offset()
		var t: float = 1.0 - pow(2.0, -lerp_speed * delta)
		global_position = global_position.lerp(target, t)

	offset = _update_shake(delta)

func _get_offset() -> Vector2:
	var raw:Vector2 = get_global_mouse_position() - player.global_position
	var dist:float = raw.length()

	if dist <= dead_zone:
		return Vector2.ZERO

	var effective:float = min(dist - dead_zone, max_offset - dead_zone)
	return raw.normalized() * effective

func set_ambient_shake(intensity: float) -> void:
	_ambient_shake = intensity

func add_shake_burst(intensity: float) -> void:
	_burst_shake = max(_burst_shake, intensity)

func _update_shake(delta: float) -> Vector2:
	var total: float = _ambient_shake + _burst_shake
	if total <= 0.0:
		return Vector2.ZERO

	_shake_timer += delta * 18.0
	var result := Vector2(
		sin(_shake_timer * 1.3) * total,
		cos(_shake_timer * 1.7) * total * 0.5
	)

	_burst_shake = max(_burst_shake - delta * 2.0, 0.0)
	return result
