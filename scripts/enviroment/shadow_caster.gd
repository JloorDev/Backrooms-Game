extends Node2D
class_name ShadowCaster

@export var sprite_path: NodePath = NodePath("../Sprite")
@export var shadow_alpha: float = 0.35
@export var squash: float = 1.0
@export var invert_light_direction: bool = false

@export var debug_light_dir: Vector2 = Vector2.ZERO

var _source_sprite: Sprite2D

func _ready() -> void:
	_source_sprite = get_node(sprite_path)
	z_as_relative = false
	z_index = 1

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not _source_sprite or not _source_sprite.texture:
		return

	var dir: Vector2 = _get_light_dir()
	if dir == Vector2.ZERO:
		return

	var tex: Texture2D = _source_sprite.texture
	var size: Vector2 = tex.get_size()

	var draw_pos: Vector2 = -size / 2.0 if _source_sprite.centered else Vector2.ZERO
	draw_pos += _source_sprite.offset

	var angle: float = dir.angle() + PI / 2.0
	var x_axis := Vector2(cos(angle), sin(angle))
	var y_axis := Vector2(-sin(angle), cos(angle)) * squash

	draw_set_transform_matrix(Transform2D(x_axis, y_axis, Vector2.ZERO))
	draw_texture_rect(tex, Rect2(draw_pos, size), false, Color(0, 0, 0, shadow_alpha))

func _get_light_dir() -> Vector2:
	var dir: Vector2
	if debug_light_dir != Vector2.ZERO:
		dir = debug_light_dir.normalized()
	else:
		var light := _find_nearest_light()
		if light == null:
			return Vector2.ZERO
		var to_object: Vector2 = global_position - light.global_position
		if to_object.length() < 0.001:
			return Vector2.ZERO
		dir = to_object.normalized()

	if invert_light_direction:
		dir = -dir
	return dir

func _find_nearest_light() -> Node2D:
	var lights := get_tree().get_nodes_in_group("dynamic_lights")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for l in lights:
		if not (l is PointLight2D) or not l.visible or l.energy <= 0.01:
			continue
		var d: float = global_position.distance_squared_to(l.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = l
	return nearest
