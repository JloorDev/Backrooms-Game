extends ItemData
class_name EquipmentData

@export var equip_slot: String = "bag"
@export var hotbar_slot_bonus: int = 0
@export var player_sprite: Texture2D = null

@export var internal_grid_width: int = 3
@export var internal_grid_height: int = 2
@export var internal_max_weight: float = 15.0

@export_range(0.0, 1.0, 0.05) var external_weight_multiplier: float = 0.3

func get_stat_lines() -> Array[String]:
	var lines: Array[String] = []
	if hotbar_slot_bonus != 0:
		lines.append("Hotbar slots: +%d" % hotbar_slot_bonus)
	lines.append("Internal space: %dx%d" % [internal_grid_width, internal_grid_height])
	lines.append("Max internal weight: %.1f" % internal_max_weight)
	lines.append("Reduces its contents' weight by %d%%" % roundi((1.0 - external_weight_multiplier) * 100.0))
	return lines
