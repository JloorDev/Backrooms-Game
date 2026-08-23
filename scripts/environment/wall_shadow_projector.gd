extends Node2D
class_name WallShadowProjector

@export var max_distance: float = 200.0
@export var patch_strength: float = 0.8
@export var patch_width: float = 15.0
@export var patch_height: float = 30.0

@export_flags_2d_physics var wall_collision_mask: int = 17  # bits 1 y 5 = 1 + 16

@export var occluder_half_width: float = 4.0
@export var smoothing_speed: float = 10.0
@export var raycast_interval: float = 0.08

var _wall_state: Dictionary = {}
var _raycast_timer: float = 0.0
var _cached_hit_walls: Dictionary = {}
var _cached_effective_strength: float = 0.0

func _ready() -> void:
	# Desfasa el arranque de cada columna para que no todas recalculen
	# sus raycasts en el mismo frame exacto -- reparte la carga en el tiempo.
	_raycast_timer = randf() * raycast_interval

func _process(delta: float) -> void:
	_raycast_timer += delta
	if _raycast_timer >= raycast_interval:
		_raycast_timer = 0.0
		_refresh_raycast()

	_update_smoothing(delta)

func _refresh_raycast() -> void:
	var light := _find_nearest_light()
	_cached_hit_walls = {}
	_cached_effective_strength = 0.0

	if light == null:
		return

	var dir := _get_shadow_direction(light)
	if dir == Vector2.ZERO:
		return

	var energy_ratio := _get_light_energy_ratio(light)
	_cached_effective_strength = patch_strength * energy_ratio
	_cached_hit_walls = _raycast_fan(dir)

func _update_smoothing(delta: float) -> void:
	var hit_walls := _cached_hit_walls
	var effective_strength := _cached_effective_strength

	var walls_to_update: Array = hit_walls.keys()
	for w in _wall_state.keys():
		if not walls_to_update.has(w):
			walls_to_update.append(w)

	var t: float = clamp(smoothing_speed * delta, 0.0, 1.0)

	for wall in walls_to_update:
		if not is_instance_valid(wall):
			_wall_state.erase(wall)
			continue

		var sprite: Sprite2D = wall.get_node_or_null("Sprite")
		if not sprite or not sprite.material:
			continue

		var is_hit: bool = hit_walls.has(wall)

		if not _wall_state.has(wall):
			var start_point: Vector2 = sprite.to_local(hit_walls[wall]) if is_hit else Vector2.ZERO
			_wall_state[wall] = {"point": start_point, "strength": 0.0}

		var state: Dictionary = _wall_state[wall]
		var target_point: Vector2 = sprite.to_local(hit_walls[wall]) if is_hit else state["point"]
		var target_strength: float = effective_strength if is_hit else 0.0

		state["point"] = state["point"].lerp(target_point, t)
		state["strength"] = lerp(state["strength"], target_strength, t)
		_wall_state[wall] = state

		_set_wall_shader(sprite, state["point"], state["strength"])

		if not is_hit and state["strength"] < 0.01:
			_set_wall_shader(sprite, state["point"], 0.0)
			_wall_state.erase(wall)

func _get_shadow_direction(light: PointLight2D) -> Vector2:
	var to_object: Vector2 = global_position - light.global_position
	if to_object.length() < 0.001:
		return Vector2.ZERO
	return to_object.normalized()

func _find_nearest_light() -> PointLight2D:
	var lights := get_tree().get_nodes_in_group("dynamic_lights")
	var nearest: PointLight2D = null
	var nearest_dist: float = INF
	for l in lights:
		if not (l is PointLight2D) or not l.visible or l.energy <= 0.01:
			continue
		var d: float = global_position.distance_squared_to(l.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = l
	return nearest

func _get_light_energy_ratio(light: PointLight2D) -> float:
	var base = light.get("base_energy")
	if base == null or base <= 0.0:
		return 1.0
	return clamp(light.energy / base, 0.0, 1.0)

func _get_excluded_bodies() -> Array:
	var excluded: Array = [get_parent()]
	excluded.append_array(get_tree().get_nodes_in_group("player"))
	return excluded

func _raycast_fan(dir: Vector2) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var perp: Vector2 = dir.orthogonal()
	var offsets: Array[float] = [0.0, -occluder_half_width, occluder_half_width]
	var excluded := _get_excluded_bodies()
	var hits: Dictionary = {}

	for offset in offsets:
		var from: Vector2 = global_position + perp * offset
		var to: Vector2 = from + dir * max_distance

		var query := PhysicsRayQueryParameters2D.create(from, to)
		query.collision_mask = wall_collision_mask
		query.exclude = excluded

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		if not result.collider.is_in_group("shadow_receivers"):
			continue

		hits[result.collider] = result.position

	return hits

func _set_wall_shader(sprite: Sprite2D, local_point: Vector2, strength: float) -> void:
	sprite.material.set_shader_parameter("shadow_point", local_point)
	sprite.material.set_shader_parameter("shadow_radius", Vector2(patch_width, patch_height))
	sprite.material.set_shader_parameter("shadow_strength", strength)
