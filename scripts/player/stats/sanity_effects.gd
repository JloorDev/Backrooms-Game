extends Node
class_name SanityEffects

@export var camera_path: NodePath
@export var canvas_layer_path: NodePath

@onready var camera: Camera2D = get_node(camera_path)

var _overlay: ColorRect
var _current_sanity: float = 1.0

const SHAKE_THRESHOLD   = 0.50   # Empieza a temblar
const BLUR_THRESHOLD    = 0.40   # Bordes se oscurecen
const CONTROL_THRESHOLD = 0.25   # Controles fallan

func _ready() -> void:
	_setup_overlay()

func _setup_overlay() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)

	_overlay = ColorRect.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	canvas.add_child(_overlay)

	_resize_overlay()
	get_viewport().size_changed.connect(_resize_overlay)

func _resize_overlay() -> void:
	if _overlay:
		_overlay.position = Vector2.ZERO
		_overlay.size = get_viewport().get_visible_rect().size

func _process(_delta: float) -> void:
	_update_overlay()

func on_sanity_changed(_value: float, percent: float) -> void:
	_current_sanity = percent

	if camera:
		if percent < SHAKE_THRESHOLD:
			var intensity = (SHAKE_THRESHOLD - percent) / SHAKE_THRESHOLD
			camera.set_ambient_shake(intensity * 4.0)   # máximo 4px de shake
		else:
			camera.set_ambient_shake(0.0)

func _update_overlay() -> void:
	if _current_sanity < BLUR_THRESHOLD:
		var intensity = (BLUR_THRESHOLD - _current_sanity) / BLUR_THRESHOLD
		_overlay.color = Color(0.0, 0.0, 0.02, intensity * 0.65)
	else:
		_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

func get_input_noise() -> Vector2:
	if _current_sanity >= CONTROL_THRESHOLD:
		return Vector2.ZERO
	var intensity = (CONTROL_THRESHOLD - _current_sanity) / CONTROL_THRESHOLD
	return Vector2(
		randf_range(-1.0, 1.0) * intensity * 0.4,
		randf_range(-1.0, 1.0) * intensity * 0.2
	)

func get_speed_penalty() -> float:
	if _current_sanity > 0.50:
		return 1.0
	return lerp(0.70, 1.0, _current_sanity / 0.50)
