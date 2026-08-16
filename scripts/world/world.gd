extends Node

const CHUNK_SIZE     = 24
const ACTIVE_RADIUS  = 3
const TILE_THRESHOLD = 4
const SOURCE_ID      = 0

const TILE_FLOOR := Vector2i(0, 0)

const WALLS_PER_FRAME = 8

@onready var tile_map: TileMapLayer  = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../YSortRoot/Player"
@onready var walls_root: Node2D      = $"../YSortRoot/Walls"
@onready var columns_root: Node2D    = $"../YSortRoot/Columns"
@onready var lights_root: Node2D = $"../Lights"

var light_scene: PackedScene
var light_instances: Dictionary = {}
var _lights_queue: Array = []

var wall_scene:   PackedScene
var column_scene: PackedScene

var world_seed: int
var loaded_chunks: Dictionary    = {}
var chunk_pool: Array            = []
var chunks_to_load: Array        = []
var wall_instances: Dictionary   = {}
var column_instances: Dictionary = {}

var _walls_queue:   Array = []
var _columns_queue: Array = []

var last_chunk:    Vector2i = Vector2i(99999, 99999)
var last_tile_pos: Vector2i = Vector2i(99999, 99999)

var _initial_chunks: Array       = []
var _initial_total:  int         = 0
var _initial_done:   int         = 0
var _loading_screen: Node        = null
var _initial_load_complete: bool = false

signal initial_load_complete

func _ready() -> void:
	world_seed   = randi()
	wall_scene   = load("res://prefabs/world/wall.tscn")
	column_scene = load("res://prefabs/world/column.tscn")
	light_scene = load("res://prefabs/world/ceiling_light.tscn")

	for dy in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
		for dx in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
			_initial_chunks.append(Vector2i(dx, dy))

	_initial_total = _initial_chunks.size()
	player.visible = false
	player.set_physics_process(false)

func start_with_loading(loading_screen: Node) -> void:
	_loading_screen = loading_screen

func _process(_delta: float) -> void:
	if not _initial_load_complete:
		_process_initial_load()
		return

	var tile_pos = tile_map.local_to_map(player.global_position)
	if tile_pos.distance_squared_to(last_tile_pos) < TILE_THRESHOLD * TILE_THRESHOLD:
		_process_instance_queues()
		if not chunks_to_load.is_empty():
			_load_chunk(chunks_to_load.pop_front())
		return

	last_tile_pos = tile_pos
	var current_chunk = _to_chunk_coord(tile_pos)
	if current_chunk != last_chunk:
		last_chunk = current_chunk
		_update_chunks(current_chunk)
	_process_instance_queues()
	if not chunks_to_load.is_empty():
		_load_chunk(chunks_to_load.pop_front())

func _process_initial_load() -> void:
	if _initial_chunks.is_empty():
		_flush_queues()
		_initial_load_complete = true
		_initial_load_finished()
		return
	var coord = _initial_chunks.pop_front()
	_load_chunk(coord)
	_initial_done += 1
	if _loading_screen:
		_loading_screen.set_progress(float(_initial_done) / float(_initial_total))

func _initial_load_finished() -> void:
	_spawn_player_on_floor()
	player.visible = true
	player.set_physics_process(true)
	last_chunk = _to_chunk_coord(tile_map.local_to_map(player.global_position))
	initial_load_complete.emit()
	if _loading_screen:
		_loading_screen.finish()

func _spawn_player_on_floor() -> void:
	for r in range(CHUNK_SIZE):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var tile = Vector2i(dx, dy)
				if _is_safe_spawn(tile):
					player.global_position = tile_map.map_to_local(tile)
					return

func _is_safe_spawn(tile: Vector2i) -> bool:
	var neighbors = [
		tile,
		tile + Vector2i(1, 0), tile + Vector2i(-1, 0),
		tile + Vector2i(0, 1), tile + Vector2i(0, -1),
	]
	for n in neighbors:
		var chunk_coord = _to_chunk_coord(n)
		if not loaded_chunks.has(chunk_coord):
			return false
		if loaded_chunks[chunk_coord].cells.get(n, -1) != Chunk.CELL_FLOOR:
			return false
	return true

func _process_instance_queues() -> void:
	var budget = WALLS_PER_FRAME

	while budget > 0 and not _walls_queue.is_empty():
		var cell_pos: Vector2i = _walls_queue.pop_front()
		if not wall_instances.has(cell_pos):
			var wall = wall_scene.instantiate()
			walls_root.add_child(wall)
			wall.position = tile_map.map_to_local(cell_pos) + Vector2(0, 4)
			wall_instances[cell_pos] = wall
		budget -= 1

	while not _columns_queue.is_empty():
		var col_pos: Vector2i = _columns_queue.pop_front()
		if not column_instances.has(col_pos):
			var col = column_scene.instantiate()
			columns_root.add_child(col)
			col.position = tile_map.map_to_local(col_pos) + Vector2(0, 4)
			column_instances[col_pos] = col
	
	while not _lights_queue.is_empty():
		var light_pos: Vector2i = _lights_queue.pop_front()
		if not light_instances.has(light_pos):
			var light = light_scene.instantiate()
			lights_root.add_child(light)
			light.position = tile_map.map_to_local(light_pos) + Vector2(0, -8)
			light_instances[light_pos] = light

func _flush_queues() -> void:
	for cell_pos in _walls_queue:
		if not wall_instances.has(cell_pos):
			var wall = wall_scene.instantiate()
			walls_root.add_child(wall)
			wall.position = tile_map.map_to_local(cell_pos) + Vector2(0, 4)
			wall_instances[cell_pos] = wall
	_walls_queue.clear()

	for col_pos in _columns_queue:
		if not column_instances.has(col_pos):
			var col = column_scene.instantiate()
			columns_root.add_child(col)
			col.position = tile_map.map_to_local(col_pos) + Vector2(0, 4)
			column_instances[col_pos] = col
	_columns_queue.clear()
	
	for light_pos in _lights_queue:
		if not light_instances.has(light_pos):
			var light = light_scene.instantiate()
			lights_root.add_child(light)
			light.position = tile_map.map_to_local(light_pos) + Vector2(0, -8)
			light_instances[light_pos] = light
	_lights_queue.clear()

func _update_chunks(center: Vector2i) -> void:
	var needed := {}
	for dy in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
		for dx in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
			var coord = center + Vector2i(dx, dy)
			needed[coord] = true
			if not loaded_chunks.has(coord) and not chunks_to_load.has(coord):
				chunks_to_load.append(coord)
	for coord in loaded_chunks.keys():
		if not needed.has(coord):
			_unload_chunk(coord)

func _load_chunk(coord: Vector2i) -> void:
	var chunk: Chunk = _get_chunk()
	chunk.generate(coord, world_seed)
	loaded_chunks[coord] = chunk

	for cell_pos in chunk.cells:
		if chunk.cells[cell_pos] == Chunk.CELL_FLOOR:
			tile_map.set_cell(cell_pos, SOURCE_ID, TILE_FLOOR)

	for cell_pos in chunk.cells:
		if chunk.cells[cell_pos] == Chunk.CELL_WALL:
			if _borders_floor_global(cell_pos) and not wall_instances.has(cell_pos):
				if not cell_pos in _walls_queue:
					_walls_queue.append(cell_pos)

	_refresh_neighbor_borders(coord)

	for col_pos in chunk.columns:
		if not column_instances.has(col_pos):
			if not col_pos in _columns_queue:
				_columns_queue.append(col_pos)
	
	for light_pos in chunk.lights:
		if not light_instances.has(light_pos):
			if not light_pos in _lights_queue:
				_lights_queue.append(light_pos)

func _unload_chunk(coord: Vector2i) -> void:
	var chunk: Chunk = loaded_chunks[coord]

	for cell_pos in chunk.cells.keys():
		match chunk.cells[cell_pos]:
			Chunk.CELL_FLOOR:
				tile_map.erase_cell(cell_pos)
			Chunk.CELL_WALL:
				if wall_instances.has(cell_pos):
					wall_instances[cell_pos].queue_free()
					wall_instances.erase(cell_pos)
				_walls_queue.erase(cell_pos)

	for col_pos in chunk.columns:
		if column_instances.has(col_pos):
			column_instances[col_pos].queue_free()
			column_instances.erase(col_pos)
		_columns_queue.erase(col_pos)
	
	for light_pos in chunk.lights:
		if light_instances.has(light_pos):
			light_instances[light_pos].queue_free()
			light_instances.erase(light_pos)
		_lights_queue.erase(light_pos)

	chunk.cells.clear()
	chunk.columns.clear()
	chunk.lights.clear()
	chunk_pool.append(chunk)
	loaded_chunks.erase(coord)

func _borders_floor_global(pos: Vector2i) -> bool:
	var neighbors = [
		Vector2i(pos.x+1, pos.y), Vector2i(pos.x-1, pos.y),
		Vector2i(pos.x, pos.y+1), Vector2i(pos.x, pos.y-1)
	]
	for n in neighbors:
		var chunk_coord = _to_chunk_coord(n)
		if loaded_chunks.has(chunk_coord):
			if loaded_chunks[chunk_coord].cells.get(n, -1) == Chunk.CELL_FLOOR:
				return true
	return false

func _refresh_neighbor_borders(coord: Vector2i) -> void:
	var neighbor_coords = [
		coord + Vector2i(1, 0), coord + Vector2i(-1, 0),
		coord + Vector2i(0, 1), coord + Vector2i(0, -1)
	]
	for nc in neighbor_coords:
		if not loaded_chunks.has(nc):
			continue
		var border_cells = _get_shared_border(coord, nc)
		var neighbor = loaded_chunks[nc]
		for cell_pos in border_cells:
			if neighbor.cells.get(cell_pos, -1) == Chunk.CELL_WALL:
				if not wall_instances.has(cell_pos) and not cell_pos in _walls_queue:
					if _borders_floor_global(cell_pos):
						_walls_queue.append(cell_pos)

func _get_shared_border(a: Vector2i, b: Vector2i) -> Array:
	var result: Array = []
	var b_offset = b * CHUNK_SIZE
	var diff = b - a

	if diff.x == 1:
		for y in range(CHUNK_SIZE):
			result.append(Vector2i(b_offset.x, b_offset.y + y))
	elif diff.x == -1:
		for y in range(CHUNK_SIZE):
			result.append(Vector2i(b_offset.x + CHUNK_SIZE - 1, b_offset.y + y))
	elif diff.y == 1:
		for x in range(CHUNK_SIZE):
			result.append(Vector2i(b_offset.x + x, b_offset.y))
	elif diff.y == -1:
		for x in range(CHUNK_SIZE):
			result.append(Vector2i(b_offset.x + x, b_offset.y + CHUNK_SIZE - 1))

	return result

func _get_chunk() -> Chunk:
	if chunk_pool.size() > 0:
		return chunk_pool.pop_back()
	return Chunk.new()

func _to_chunk_coord(tile: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(tile.x) / CHUNK_SIZE),
		floori(float(tile.y) / CHUNK_SIZE)
	)
