class_name RoomStamper

class StampResult:
	var cells:   Dictionary = {}  # Vector2i -> CELL_FLOOR (0)
	var columns: Array      = []  # Vector2i

class Template:
	var cells:   Array    = []          # Vector2i relativos al origen del prefab
	var columns: Array    = []          # Vector2i relativos (reservado a futuro)
	var size:    Vector2i = Vector2i.ZERO

# Cache de plantillas — cada prefab se carga e instancia UNA sola vez
# en toda la partida. Las siguientes veces que se usa, solo se
# desplazan las celdas ya guardadas, sin tocar disco ni instanciar nodos.
static var _cache: Dictionary = {}  # scene_path -> Template

# Llamar durante la pantalla de carga para dejar todo cacheado
# antes de que empiece la generación real del mundo.
static func preload_template(scene_path: String) -> void:
	_get_template(scene_path)

static func _get_template(scene_path: String) -> Template:
	if _cache.has(scene_path):
		return _cache[scene_path]

	var tpl = Template.new()
	var scene = load(scene_path)
	if scene:
		var inst = scene.instantiate()
		var map: TileMapLayer = inst.get_node_or_null("TileMapLayer")
		if map:
			tpl.cells = map.get_used_cells()
			tpl.size  = map.get_used_rect().size
		else:
			push_warning("RoomStamper: sin TileMapLayer en " + scene_path)
		inst.queue_free()
	else:
		push_warning("RoomStamper: no se pudo cargar " + scene_path)

	_cache[scene_path] = tpl
	return tpl

static func stamp_from_scene(scene_path: String, ox: int, oy: int) -> StampResult:
	var r   = StampResult.new()
	var tpl = _get_template(scene_path)
	for cell in tpl.cells:
		r.cells[Vector2i(cell.x + ox, cell.y + oy)] = 0
	return r

static func stamp_corridor(scene_path: String, from: Vector2i, to: Vector2i) -> StampResult:
	var r   = StampResult.new()
	var tpl = _get_template(scene_path)

	if tpl.cells.is_empty() or tpl.size.y == 0:
		return r

	var template_w = tpl.size.x
	var template_h = tpl.size.y

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
			for cell in tpl.cells:
				var new_x = start.x + rep * template_h + cell.y
				var new_y = center_y + cell.x
				if new_x <= start.x + distance:
					r.cells[Vector2i(new_x, new_y)] = 0
	else:
		var repeats  = ceili(float(distance) / float(template_h))
		var center_x = start.x - template_w / 2

		for rep in range(repeats):
			for cell in tpl.cells:
				var new_x = center_x + cell.x
				var new_y = start.y  + rep * template_h + cell.y
				if new_y <= start.y + distance:
					r.cells[Vector2i(new_x, new_y)] = 0

	return r

static func get_scene_size(scene_path: String) -> Vector2i:
	var tpl = _get_template(scene_path)
	if tpl.size == Vector2i.ZERO:
		return Vector2i(8, 8)
	return tpl.size
