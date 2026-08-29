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
		lines.append(ItemData.format_stat("Thirst", thirst_restore))
	if hunger_restore != 0.0:
		lines.append(ItemData.format_stat("Hunger", hunger_restore))
	if sanity_restore != 0.0:
		lines.append(ItemData.format_stat("Sanity", sanity_restore))
	if health_restore != 0.0:
		lines.append(ItemData.format_stat("Health", health_restore))
	if stamina_restore != 0.0:
		lines.append(ItemData.format_stat("Stamina", stamina_restore))
	return lines
