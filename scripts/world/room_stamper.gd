class_name RoomStamper

class StampResult:
	var cells:   Dictionary = {}  # Vector2i -> CELL_FLOOR (0)
	var columns: Array      = []  # Vector2i

static func stamp_from_scene(scene_path: String, ox: int, oy: int) -> StampResult:
	var r = StampResult.new()
	var scene = load(scene_path)
	if not scene:
		push_warning("RoomStamper: no se pudo cargar " + scene_path)
		return r

	var inst = scene.instantiate()
	var map: TileMapLayer = inst.get_node_or_null("TileMapLayer")
	if not map:
		push_warning("RoomStamper: sin TileMapLayer en " + scene_path)
		inst.queue_free()
		return r

	for cell in map.get_used_cells():
		r.cells[Vector2i(cell.x + ox, cell.y + oy)] = 0

	inst.queue_free()
	return r

static func stamp_corridor(scene_path: String, from: Vector2i, to: Vector2i) -> StampResult:
	var r = StampResult.new()
	var scene = load(scene_path)
	if not scene:
		push_warning("RoomStamper: no se pudo cargar " + scene_path)
		return r

	var inst = scene.instantiate()
	var map: TileMapLayer = inst.get_node_or_null("TileMapLayer")
	if not map:
		inst.queue_free()
		return r

	var template_cells = map.get_used_cells()
	var rect           = map.get_used_rect()
	var template_w     = rect.size.x
	var template_h     = rect.size.y
	inst.queue_free()

	if template_cells.is_empty() or template_h == 0:
		return r

	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var is_horizontal = dx > dy

	var distance = maxi(dx, dy)
	if distance == 0:
		return r

	var start = Vector2i(mini(from.x, to.x), mini(from.y, to.y))

	if is_horizontal:
		var repeats  = ceili(float(distance) / float(template_h))
		var center_y = start.y - template_w / 2

		for rep in range(repeats):
			for cell in template_cells:
				var new_x = start.x + rep * template_h + cell.y
				var new_y = center_y + cell.x
				if new_x <= start.x + distance:
					r.cells[Vector2i(new_x, new_y)] = 0
	else:
		var repeats  = ceili(float(distance) / float(template_h))
		var center_x = start.x - template_w / 2

		for rep in range(repeats):
			for cell in template_cells:
				var new_x = center_x + cell.x
				var new_y = start.y  + rep * template_h + cell.y
				if new_y <= start.y + distance:
					r.cells[Vector2i(new_x, new_y)] = 0

	return r

static func get_scene_size(scene_path: String) -> Vector2i:
	var scene = load(scene_path)
	if not scene:
		return Vector2i(8, 8)
	var inst = scene.instantiate()
	var map: TileMapLayer = inst.get_node_or_null("TileMapLayer")
	if not map:
		inst.queue_free()
		return Vector2i(8, 8)
	var rect = map.get_used_rect()
	inst.queue_free()
	return Vector2i(rect.size.x, rect.size.y)
