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
		lines.append("Sed: %+.0f" % thirst_restore)
	if hunger_restore != 0.0:
		lines.append("Hambre: %+.0f" % hunger_restore)
	if sanity_restore != 0.0:
		lines.append("Cordura: %+.0f" % sanity_restore)
	if health_restore != 0.0:
		lines.append("Salud: %+.0f" % health_restore)
	if stamina_restore != 0.0:
		lines.append("Resistencia: %+.0f" % stamina_restore)
	return lines
