class_name EquippedBag
extends RefCounted

var data: EquipmentData
var grid: ItemGrid

func _init(bag_data: EquipmentData) -> void:
	data = bag_data
	grid = ItemGrid.new(bag_data.internal_grid_width, bag_data.internal_grid_height, bag_data.internal_max_weight)

func get_total_weight() -> float:
	return data.weight + grid.get_current_weight()
