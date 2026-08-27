class_name ItemGrid
extends RefCounted

## Contenedor de inventario con grilla 2D real -- un ítem puede ocupar
## más de una celda según item.grid_width/grid_height.
##
## Se usa para el inventario del cuerpo Y para el interior de las mochilas
## equipadas (cada EquippedBag tiene el suyo) -- por eso cada entrada
## colocada se guarda a sí misma un puntero a "grid" (ver place_item):
## así, cuando movés un ítem por drag&drop, el código que recibe el drop
## sabe de dónde vino sin que nadie tenga que pasarle ese dato aparte.
## - JloorDev

var width: int
var height: int
var max_weight: float

var _cells: Array = []      # width*height; cada celda: null o el Dictionary del ítem colocado ahí
var _placed: Array = []     # lista de { data: ItemData, quantity: int, origin: Vector2i, grid: ItemGrid }

func _init(w: int, h: int, weight_limit: float) -> void:
	width = w
	height = h
	max_weight = weight_limit
	_cells.resize(w * h)
	_cells.fill(null)

func _index(x: int, y: int) -> int:
	return y * width + x

func _in_bounds(origin: Vector2i, size: Vector2i) -> bool:
	return origin.x >= 0 and origin.y >= 0 \
		and origin.x + size.x <= width and origin.y + size.y <= height

func can_place_at(item: ItemData, origin: Vector2i) -> bool:
	var size := Vector2i(item.grid_width, item.grid_height)
	if not _in_bounds(origin, size):
		return false
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			if _cells[_index(x, y)] != null:
				return false
	return true

## Busca el primer lugar libre (de arriba a abajo, izquierda a derecha)
## donde el ítem completo entre. Devuelve un Vector2i, o null si no cabe.
func find_free_spot(item: ItemData) -> Variant:
	var size := Vector2i(item.grid_width, item.grid_height)
	for y in range(height - size.y + 1):
		for x in range(width - size.x + 1):
			var origin := Vector2i(x, y)
			if can_place_at(item, origin):
				return origin
	return null

func place_item(data: ItemData, origin: Vector2i, quantity: int = 1) -> bool:
	if not can_place_at(data, origin):
		return false
	var entry := { "data": data, "quantity": quantity, "origin": origin, "grid": self }
	var size := Vector2i(data.grid_width, data.grid_height)
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			_cells[_index(x, y)] = entry
	_placed.append(entry)
	return true

## Conveniencia: busca espacio libre solo y lo coloca ahí.
func add_item(data: ItemData, quantity: int = 1) -> bool:
	var spot = find_free_spot(data)
	if spot == null:
		return false
	return place_item(data, spot, quantity)

## Devuelve la entrada colocada en esa celda, o null si esta vacia.
func get_entry_at(x: int, y: int) -> Variant:
	if x < 0 or y < 0 or x >= width or y >= height:
		return null
	return _cells[_index(x, y)]

## Como can_place_at, pero ignora las celdas que ya ocupa `ignore_entry` --
## necesario para mover un ítem sin que choque consigo mismo.
func can_place_at_ignoring(item: ItemData, origin: Vector2i, ignore_entry: Dictionary) -> bool:
	var size := Vector2i(item.grid_width, item.grid_height)
	if not _in_bounds(origin, size):
		return false
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			var cell = _cells[_index(x, y)]
			if cell != null and cell != ignore_entry:
				return false
	return true

## Mueve una entrada ya colocada a un nuevo origen. Devuelve false (sin
## mover nada) si no cabe ahí.
func move_item(entry: Dictionary, new_origin: Vector2i) -> bool:
	if not can_place_at_ignoring(entry.data, new_origin, entry):
		return false

	var size := Vector2i(entry.data.grid_width, entry.data.grid_height)
	var old_origin: Vector2i = entry.origin

	for y in range(old_origin.y, old_origin.y + size.y):
		for x in range(old_origin.x, old_origin.x + size.x):
			if _cells[_index(x, y)] == entry:
				_cells[_index(x, y)] = null

	entry.origin = new_origin
	for y in range(new_origin.y, new_origin.y + size.y):
		for x in range(new_origin.x, new_origin.x + size.x):
			_cells[_index(x, y)] = entry

	return true

func remove_item(entry: Dictionary) -> void:
	if not _placed.has(entry):
		return
	var size := Vector2i(entry.data.grid_width, entry.data.grid_height)
	var origin: Vector2i = entry.origin
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			_cells[_index(x, y)] = null
	_placed.erase(entry)

func get_current_weight() -> float:
	var total := 0.0
	for entry in _placed:
		total += entry.data.weight * entry.quantity
	return total

func is_overweight() -> bool:
	return get_current_weight() > max_weight

## Solo para depurar mientras probamos esto sin UI -- imprime la grilla
## como texto, una fila por línea, "." = vacío, "#" = ocupado.
func debug_print() -> void:
	for y in height:
		var row := ""
		for x in width:
			row += "#" if _cells[_index(x, y)] != null else "."
		print(row)
