class_name LightUtils
extends RefCounted

static func get_active_lights() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []

	var result: Array = []
	for l in tree.get_nodes_in_group("dynamic_lights"):
		if l is PointLight2D and l.visible and l.energy > 0.01:
			result.append(l)
	return result

static func find_nearest(from_position: Vector2, lights: Array = []) -> PointLight2D:
	var pool: Array = lights if not lights.is_empty() else get_active_lights()
	var nearest: PointLight2D = null
	var nearest_dist: float = INF

	for l in pool:
		var d: float = from_position.distance_squared_to(l.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = l

	return nearest

static func is_position_lit(pos: Vector2, lights: Array = []) -> bool:
	var pool: Array = lights if not lights.is_empty() else get_active_lights()

	for l in pool:
		var radius = l.get("effective_radius")
		if radius == null:
			radius = 46.0
		if pos.distance_to(l.global_position) <= radius:
			return true

	return false
