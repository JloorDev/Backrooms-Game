extends Button

@export var hover_scale:    float = 1.15
@export var anim_duration:  float = 0.2

var _base_size:     Vector2 = Vector2.ZERO
var _base_position: Vector2 = Vector2.ZERO
var _tween:         Tween   = null

func _ready() -> void:
	await get_tree().process_frame
	_base_size     = size
	_base_position = position
	pivot_offset   = size / 2.0

	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)

func _on_hover_in() -> void:
	_animate(hover_scale)

func _on_hover_out() -> void:
	_animate(1.0)

func _animate(target_scale: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "scale", Vector2.ONE * target_scale, anim_duration)
