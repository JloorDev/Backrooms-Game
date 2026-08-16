class_name RoomStamper

# ─────────────────────────────────────────
#  Resultado de un stamp
# ─────────────────────────────────────────
class StampResult:
	var cells:   Dictionary = {}  # Vector2i -> CELL_FLOOR (0)
	var columns: Array      = []  # Vector2i

# ─────────────────────────────────────────
#  Stamp de habitación — copia directa con offset
# ─────────────────────────────────────────
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

# ─────────────────────────────────────────
#  Stamp de corredor — escala y rota para
#  conectar dos puntos del mundo
#
#  Los corredores se diseñan VERTICALES en
#  el editor. El stamper los rota si hace falta.
# ─────────────────────────────────────────
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

	# Leer celdas del template
	var template_cells = map.get_used_cells()
	var rect           = map.get_used_rect()
	var template_w     = rect.size.x   # ancho del corredor (eje X en el tscn)
	var template_h     = rect.size.y   # largo del corredor (eje Y en el tscn)
	inst.queue_free()

	if template_cells.is_empty() or template_h == 0:
		return r

	# Detectar si la conexión es horizontal o vertical
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var is_horizontal = dx > dy

	# Distancia real a cubrir
	var distance = maxi(dx, dy)
	if distance == 0:
		return r

	# Punto de inicio (el menor)
	var start = Vector2i(mini(from.x, to.x), mini(from.y, to.y))

	if is_horizontal:
		# ── CORREDOR HORIZONTAL ───────────────────────
		# Rotamos el template: lo que era Y pasa a ser X
		# El ancho del corredor (template_w) queda en Y
		# El largo (template_h) se escala en X
		var repeats  = ceili(float(distance) / float(template_h))
		var center_y = start.y - template_w / 2  # centrar en Y

		for rep in range(repeats):
			for cell in template_cells:
				# Rotar: nuevo_x = cell.y, nuevo_y = cell.x
				var new_x = start.x + rep * template_h + cell.y
				var new_y = center_y + cell.x
				# No salirse de la distancia real
				if new_x <= start.x + distance:
					r.cells[Vector2i(new_x, new_y)] = 0
	else:
		# ── CORREDOR VERTICAL (orientación nativa) ────
		# Repetir el template hacia abajo hasta cubrir la distancia
		var repeats  = ceili(float(distance) / float(template_h))
		var center_x = start.x - template_w / 2  # centrar en X

		for rep in range(repeats):
			for cell in template_cells:
				var new_x = center_x + cell.x
				var new_y = start.y  + rep * template_h + cell.y
				if new_y <= start.y + distance:
					r.cells[Vector2i(new_x, new_y)] = 0

	return r

# ─────────────────────────────────────────
#  Tamaño de la escena
# ─────────────────────────────────────────
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
