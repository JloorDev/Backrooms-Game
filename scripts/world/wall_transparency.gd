extends Node

@onready var tile_map: TileMapLayer  = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../YSortRoot/Player"
@onready var walls_root: Node2D      = $"../YSortRoot/Walls"
@onready var columns_root: Node2D    = $"../YSortRoot/Columns"

@export var feet_offset: Vector2 = Vector2(0, 8)

const FADE_ALPHA   = 0.3
const NORMAL_ALPHA = 1.0
const FADE_SPEED   = 8.0

const PLACEMENT_OFFSET = Vector2(0, 4)

func _process(delta: float) -> void:
	var feet_pos: Vector2 = player.global_position + feet_offset
	var player_tile: Vector2i = tile_map.local_to_map(feet_pos)
	var front_cells: Array[Vector2i] = _get_front_cells(player_tile, feet_pos)

	for wall in walls_root.get_children():
		_update_fade(wall, front_cells, delta)
	for col in columns_root.get_children():
		_update_fade(col, front_cells, delta)

func _get_front_cells(player_tile: Vector2i, feet_pos: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var candidates = [
		player_tile + Vector2i(1, 0),
		player_tile + Vector2i(0, 1),
		player_tile + Vector2i(1, 1),
	]
	for c in candidates:
		if tile_map.map_to_local(c).y > feet_pos.y:
			result.append(c)
	return result

func _update_fade(node: Node2D, front_cells: Array[Vector2i], delta: float) -> void:
	var cell: Vector2i = tile_map.local_to_map(node.global_position - PLACEMENT_OFFSET)
	var target_alpha: float = FADE_ALPHA if cell in front_cells else NORMAL_ALPHA
	var sprite = node.get_node_or_null("Sprite")
	if sprite:
		sprite.modulate.a = lerp(sprite.modulate.a, target_alpha, FADE_SPEED * delta)
