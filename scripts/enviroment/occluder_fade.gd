extends Area2D
class_name OccluderFade

@export var sprite_path: NodePath = NodePath("../Sprite")
@export var faded_alpha: float = 0.35
@export var fade_speed: float = 6.0

var _sprite: Sprite2D
var _target_alpha: float = 1.0

func _ready() -> void:
	_sprite = get_node(sprite_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_equal_approx(_sprite.modulate.a, _target_alpha):
		_sprite.modulate.a = move_toward(_sprite.modulate.a, _target_alpha, fade_speed * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_target_alpha = faded_alpha

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_target_alpha = 1.0
