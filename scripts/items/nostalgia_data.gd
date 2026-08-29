extends ItemData
class_name NostalgiaData

@export var sanity_restore:float = 0.0
@export var sanity_restore_duration:float = 0.0

func get_stat_lines() -> Array[String]:
	var lines: Array[String] = []
	if sanity_restore != 0.0:
		lines.append(ItemData.format_stat("Cordura", sanity_restore))
	if sanity_restore_duration > 0.0:
		lines.append("Duración: %.0fs" % sanity_restore_duration)
	return lines
