extends Node
class_name SanityEffects

# ─────────────────────────────────────────
#  Efectos visuales y de control según
#  el nivel de cordura del jugador
#
#  Conectar al StatsManager.sanity_changed
# ─────────────────────────────────────────

@export var camera_path: NodePath
@export var canvas_layer_path: NodePath

@onready var camera: Camera2D = get_node(camera_path)

# Overlay de distorsión — ColorRect con shader
var _overlay: ColorRect
var _shake_timer: float  = 0.0
var _shake_intensity: float = 0.0
var _current_sanity: float  = 1.0

# Valores de efecto según sanity percent
const SHAKE_THRESHOLD   = 0.50   # empieza a temblar
const BLUR_THRESHOLD    = 0.40   # bordes se oscurecen
const CONTROL_THRESHOLD = 0.25   # controles fallan

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


func _process(delta: float) -> void:
	_update_camera_shake(delta)
	_update_overlay()

# ─────────────────────────────────────────
#  Llamado desde StatsManager
# ─────────────────────────────────────────
func on_sanity_changed(_value: float, percent: float) -> void:
	_current_sanity = percent

	# Activar shake cuando la cordura baja del umbral
	if percent < SHAKE_THRESHOLD:
		var intensity = (SHAKE_THRESHOLD - percent) / SHAKE_THRESHOLD
		_shake_intensity = intensity * 4.0   # máximo 4px de shake
	else:
		_shake_intensity = 0.0

# ─────────────────────────────────────────
#  Tremblor de cámara
# ─────────────────────────────────────────
func _update_camera_shake(delta: float) -> void:
	if _shake_intensity <= 0.0 or not camera:
		return
	_shake_timer += delta * 18.0
	var offset = Vector2(
		sin(_shake_timer * 1.3) * _shake_intensity,
		cos(_shake_timer * 1.7) * _shake_intensity * 0.5
	)
	camera.offset = offset

# ─────────────────────────────────────────
#  Overlay de oscuridad en bordes
# ─────────────────────────────────────────
func _update_overlay() -> void:
	if _current_sanity < BLUR_THRESHOLD:
		var intensity = (BLUR_THRESHOLD - _current_sanity) / BLUR_THRESHOLD
		_overlay.color = Color(0.0, 0.0, 0.02, intensity * 0.65)
	else:
		_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

# ─────────────────────────────────────────
#  Penalización de controles
#  Llamado desde movement.gd
# ─────────────────────────────────────────
func get_input_noise() -> Vector2:
	if _current_sanity >= CONTROL_THRESHOLD:
		return Vector2.ZERO
	# A menor cordura, más ruido aleatorio en el input
	var intensity = (CONTROL_THRESHOLD - _current_sanity) / CONTROL_THRESHOLD
	return Vector2(
		randf_range(-1.0, 1.0) * intensity * 0.4,
		randf_range(-1.0, 1.0) * intensity * 0.2
	)

# ─────────────────────────────────────────
#  Penalización de velocidad por cordura
# ─────────────────────────────────────────
func get_speed_penalty() -> float:
	if _current_sanity > 0.50:
		return 1.0
	# 50% cordura → sin efecto, 0% → 30% más lento
	return lerp(0.70, 1.0, _current_sanity / 0.50)
