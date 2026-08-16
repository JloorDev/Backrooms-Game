extends CanvasLayer

signal loading_finished

@onready var bar: ColorRect       = $BG/Margin/Row/Left/BarTrack/Bar
@onready var spinner: Label       = $BG/Margin/Row/Right/Spinner
@onready var enter_label: Label   = $BG/Margin/Row/Right/EnterLabel
@onready var loading_label: Label = $BG/Margin/Row/Left/LoadingLabel
@onready var bg: ColorRect        = $BG

const BAR_MAX_WIDTH: float = 220.0
const SPINNER_FRAMES = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]

var _target: float        = 0.0
var _current: float       = 0.0
var _done: bool           = false
var _waiting_input: bool  = false
var _spinner_index: int   = 0
var _spinner_timer: float = 0.0
var _dot_index: int       = 0
var _dot_timer: float     = 0.0

func _ready() -> void:
	enter_label.visible = false
	bar.size = Vector2(0.0, 2.0)
	bar.position = Vector2.ZERO

func _process(delta: float) -> void:
	if not _done:
		_spinner_timer += delta
		if _spinner_timer >= 0.1:
			_spinner_timer = 0.0
			_spinner_index = (_spinner_index + 1) % SPINNER_FRAMES.size()
			spinner.text = SPINNER_FRAMES[_spinner_index]

		_dot_timer += delta
		if _dot_timer >= 0.4:
			_dot_timer = 0.0
			_dot_index = (_dot_index + 1) % 4
			loading_label.text = "GENERATING WORLD" + ".".repeat(_dot_index)

	if _waiting_input:
		return

	_current = move_toward(_current, _target, 180.0 * delta)
	bar.size = Vector2(_current, 2.0)

func set_progress(value: float) -> void:
	_target = clampf(value, 0.0, 1.0) * BAR_MAX_WIDTH

func finish() -> void:
	if _done:
		return
	_done = true
	_target = BAR_MAX_WIDTH
	await get_tree().create_timer(0.6).timeout
	spinner.visible = false
	enter_label.visible = true
	_waiting_input = true

func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_input:
		return
	if event is InputEventKey and event.pressed:
		_fade_out()
	elif event is InputEventJoypadButton and event.pressed:
		_fade_out()

func _fade_out() -> void:
	_waiting_input = false
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 0.0, 0.5)
	await tween.finished
	loading_finished.emit()
	queue_free()
