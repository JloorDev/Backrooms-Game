extends Node2D
class_name WallShadowProjector

@export var search_radius: float = 60.0
@export var alignment_threshold: float = 0.6
@export var patch_strength: float = 0.6
@export var patch_radius: float = 14.0

var _current_wall: Node2D = null

func _process(_delta: float) -> void:
	var dir := _get_shadow_direction()

	if dir == Vector2.ZERO:
		_clear_current_wall()
		return

	var target_wall := _find_best_wall(dir)

	if target_wall != _current_wall:
		_clear_current_wall()
		_current_wall = target_wall

	if _current_wall:
		_apply_patch(_current_wall)

func _get_shadow_direction() -> Vector2:
	var light := _find_nearest_light()
	if light == null:
		return Vector2.ZERO
	var to_object: Vector2 = global_position - light.global_position
	if to_object.length() < 0.001:
		return Vector2.ZERO
	return to_object.normalized()

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

func _find_best_wall(shadow_dir: Vector2) -> Node2D:
	var best: Node2D = null
	var best_score: float = alignment_threshold

	for wall in get_tree().get_nodes_in_group("shadow_receivers"):
		var to_wall: Vector2 = wall.global_position - global_position
		var dist: float = to_wall.length()
		if dist > search_radius or dist < 0.001:
			continue

		var alignment: float = shadow_dir.dot(to_wall.normalized())
		if alignment > best_score:
			best_score = alignment
			best = wall

	return best

func _apply_patch(wall: Node2D) -> void:
	var sprite: Sprite2D = wall.get_node_or_null("Sprite")
	if not sprite or not sprite.material:
		return

	var local_point: Vector2 = sprite.to_local(global_position)

	sprite.material.set_shader_parameter("shadow_point", local_point)
	sprite.material.set_shader_parameter("shadow_radius", patch_radius)
	sprite.material.set_shader_parameter("shadow_strength", patch_strength)

func _clear_current_wall() -> void:
	if _current_wall:
		var sprite: Sprite2D = _current_wall.get_node_or_null("Sprite")
		if sprite and sprite.material:
			sprite.material.set_shader_parameter("shadow_strength", 0.0)
	_current_wall = null
