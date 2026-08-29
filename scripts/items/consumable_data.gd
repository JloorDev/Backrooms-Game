extends ItemData
class_name ConsumableData

@export var thirst_restore:float = 0.0
@export var hunger_restore:float = 0.0
@export var sanity_restore:float = 0.0
@export var health_restore:float = 0.0
@export var stamina_restore:float = 0.0

func get_stat_lines() -> Array[String]:
	var lines: Array[String] = []
	if thirst_restore != 0.0:
		lines.append(ItemData.format_stat("Sed", thirst_restore))
	if hunger_restore != 0.0:
		lines.append(ItemData.format_stat("Hambre", hunger_restore))
	if sanity_restore != 0.0:
		lines.append(ItemData.format_stat("Cordura", sanity_restore))
	if health_restore != 0.0:
		lines.append(ItemData.format_stat("Salud", health_restore))
	if stamina_restore != 0.0:
		lines.append(ItemData.format_stat("Resistencia", stamina_restore))
	return lines
