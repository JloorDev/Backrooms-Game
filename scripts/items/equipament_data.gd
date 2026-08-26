extends ItemData
class_name EquipmentData

@export var equip_slot: String = "bag"
@export var hotbar_slot_bonus: int = 0
@export var player_sprite: Texture2D = null

@export var internal_grid_width: int = 3
@export var internal_grid_height: int = 2
@export var internal_max_weight: float = 15.0

func get_stat_lines() -> Array[String]:
	var lines: Array[String] = []
	if hotbar_slot_bonus != 0:
		lines.append("Slots de hotbar: +%d" % hotbar_slot_bonus)
	lines.append("Espacio interno: %dx%d" % [internal_grid_width, internal_grid_height])
	lines.append("Peso interno máx: %.1f" % internal_max_weight)
	return lines
