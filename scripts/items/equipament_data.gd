extends ItemData
class_name EquipmentData

@export var equip_slot: String = "bag"
@export var hotbar_slot_bonus: int = 0
@export var weight_bonus: float = 0.0
@export var player_sprite: Texture2D = null

func get_stat_lines() -> Array[String]:
	var lines: Array[String] = []
	if hotbar_slot_bonus != 0:
		lines.append("Slots de hotbar: +%d" % hotbar_slot_bonus)
	if weight_bonus != 0.0:
		lines.append("Peso máximo: +%.1f" % weight_bonus)
	return lines
