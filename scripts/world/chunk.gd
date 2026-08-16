class_name Chunk
extends RefCounted

const CHUNK_SIZE    = 24
const CELL_FLOOR    = 0
const CELL_WALL     = 1
const BORDER_OFFSET = 8
const COL_SPACING   = 4

const PREFAB_ROOM_CHANCE     = 0.30
const PREFAB_CORRIDOR_CHANCE = 0.20

const LIGHT_CHANCE = 0.00
const SECOND_LIGHT_CHANCE = 0.40

var chunk_coord: Vector2i
var cells:   Dictionary = {}
var columns: Array      = []
var lights: Array = []

func generate(coord: Vector2i, base_seed: int) -> void:
	chunk_coord = coord
	cells.clear()
	columns.clear()
	lights.clear()

	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(coord.x * 7919 + base_seed, coord.y * 6271 + base_seed))

	var offset = coord * CHUNK_SIZE

	for y in range(CHUNK_SIZE):
		for x in range(CHUNK_SIZE):
			cells[Vector2i(offset.x + x, offset.y + y)] = CELL_WALL

	var half  = CHUNK_SIZE / 2
	var rooms: Array = []

	for qy in range(2):
		for qx in range(2):
			var qx_start = offset.x + qx * half
			var qy_start = offset.y + qy * half

			var is_large = rng.randf() < 0.25
			var room_w = rng.randi_range(9, half - 1) if is_large else rng.randi_range(5, half - 2)
			var room_h = rng.randi_range(8, half - 1) if is_large else rng.randi_range(4, half - 2)
			room_w = mini(room_w, half - 2)
			room_h = mini(room_h, half - 2)

			var margin = 2
			var room_x = qx_start + rng.randi_range(margin, maxi(margin, half - room_w - margin))
			var room_y = qy_start + rng.randi_range(margin, maxi(margin, half - room_h - margin))
			rooms.append({"x": room_x, "y": room_y, "w": room_w, "h": room_h})

			if rng.randf() < LIGHT_CHANCE:
				var light_pos = Vector2i(room_x + room_w / 2, room_y + room_h / 2)
				lights.append(light_pos)

				if is_large and rng.randf() < SECOND_LIGHT_CHANCE:
					var second_offset = Vector2i(
						rng.randi_range(-room_w / 3, room_w / 3),
						rng.randi_range(-room_h / 3, room_h / 3)
					)
					lights.append(light_pos + second_offset)
	
			if rng.randf() < PREFAB_ROOM_CHANCE:
				_stamp_prefab_room(room_x, room_y, room_w, room_h, rng)
			else:
				_stamp_bsp_room(room_x, room_y, room_w, room_h, rng)

	# Centros para corredores
	var centers: Array = []
	for r in rooms:
		centers.append(Vector2i(r.x + r.w / 2, r.y + r.h / 2))

	_carve_corridor(centers[0], centers[1])
	_carve_corridor(centers[2], centers[3])
	_carve_corridor(centers[0], centers[2])
	_carve_corridor(centers[1], centers[3])

	# Corredor prefabricado ocasional entre centros 0 y 2
	if rng.randf() < PREFAB_CORRIDOR_CHANCE:
		_stamp_prefab_corridor(centers[0], centers[2], rng)

	# Corredores de borde — punto fijo para conectar chunks vecinos
	var bx = offset.x + BORDER_OFFSET
	var by = offset.y + BORDER_OFFSET

	_carve_to_nearest(Vector2i(bx, offset.y), centers)
	_carve_to_nearest(Vector2i(bx, offset.y + CHUNK_SIZE - 1), centers)
	_carve_to_nearest(Vector2i(offset.x, by), centers)
	_carve_to_nearest(Vector2i(offset.x + CHUNK_SIZE - 1, by), centers)

	for i in range(3):
		cells[Vector2i(bx + i, offset.y)] = CELL_FLOOR
		cells[Vector2i(bx + i, offset.y + CHUNK_SIZE - 1)] = CELL_FLOOR
		cells[Vector2i(offset.x, by + i)] = CELL_FLOOR
		cells[Vector2i(offset.x + CHUNK_SIZE - 1, by + i)] = CELL_FLOOR

func _stamp_bsp_room(rx: int, ry: int, rw: int, rh: int, rng: RandomNumberGenerator) -> void:
	for y in range(rh):
		for x in range(rw):
			cells[Vector2i(rx + x, ry + y)] = CELL_FLOOR
	_place_columns(rx, ry, rw, rh, rng)

func _stamp_prefab_room(rx: int, ry: int, rw: int, rh: int, rng: RandomNumberGenerator) -> void:
	var scene_path = PrefabRegistry.pick_room(rng)
	var result     = RoomStamper.stamp_from_scene(scene_path, rx, ry)

	for pos in result.cells:
		if cells.has(pos):
			cells[pos] = result.cells[pos]

	for col in result.columns:
		if cells.get(col, CELL_WALL) == CELL_FLOOR:
			columns.append(col)

	# Si el stamp fue vacío (escena no encontrada) usar BSP normal
	if result.cells.is_empty():
		_stamp_bsp_room(rx, ry, rw, rh, rng)

func _stamp_prefab_corridor(a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var scene_path = PrefabRegistry.pick_corridor(rng)
	var result = RoomStamper.stamp_corridor(scene_path, a, b)
 
	for pos in result.cells:
		if cells.has(pos):
			cells[pos] = result.cells[pos]
 
	for col in result.columns:
		if cells.get(col, CELL_WALL) == CELL_FLOOR:
			columns.append(col)

func _place_columns(room_x: int, room_y: int, room_w: int, room_h: int, rng: RandomNumberGenerator) -> void:
	if room_w < 5 or room_h < 5:
		return
	var inner_x = room_x + 2
	var inner_y = room_y + 2
	var inner_w = room_w - 4
	var inner_h = room_h - 4
	if inner_w < 2 or inner_h < 2:
		return
	var start_x = inner_x + rng.randi_range(0, mini(2, inner_w - 1))
	var start_y = inner_y + rng.randi_range(0, mini(2, inner_h - 1))
	var cx = start_x
	while cx <= room_x + room_w - 3:
		var cy = start_y
		while cy <= room_y + room_h - 3:
			if rng.randf() < 0.7:
				columns.append(Vector2i(cx, cy))
			cy += COL_SPACING
		cx += COL_SPACING

func _carve_to_nearest(from: Vector2i, centers: Array) -> void:
	var nearest   = centers[0]
	var best_dist = from.distance_squared_to(centers[0])
	for c in centers:
		var d = from.distance_squared_to(c)
		if d < best_dist:
			best_dist = d
			nearest   = c
	_carve_corridor(from, nearest)

func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var x      = a.x
	var step_x = sign(b.x - a.x)
	if step_x != 0:
		while x != b.x:
			cells[Vector2i(x, a.y)]     = CELL_FLOOR
			if cells.has(Vector2i(x, a.y + 1)):
				cells[Vector2i(x, a.y + 1)] = CELL_FLOOR
			if cells.has(Vector2i(x, a.y + 2)):
				cells[Vector2i(x, a.y + 2)] = CELL_FLOOR
			x += step_x
	var y      = a.y
	var step_y = sign(b.y - a.y)
	if step_y != 0:
		while y != b.y:
			cells[Vector2i(b.x, y)]     = CELL_FLOOR
			if cells.has(Vector2i(b.x + 1, y)):
				cells[Vector2i(b.x + 1, y)] = CELL_FLOOR
			if cells.has(Vector2i(b.x + 2, y)):
				cells[Vector2i(b.x + 2, y)] = CELL_FLOOR
			y += step_y
