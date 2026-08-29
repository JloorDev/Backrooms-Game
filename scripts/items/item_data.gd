extends Resource
class_name ItemData

enum Rarity { COMUN, POCO_COMUN, RARO, ANOMALO }

@export var id:String = ""
@export var display_name:String = ""
@export var description:String = ""
@export var icon:Texture2D = null
@export var weight:float = 0.1
@export var max_stack:int = 1
@export var grid_width: int = 1
@export var grid_height: int = 1
@export var rarity: Rarity = Rarity.COMUN

func get_rarity_name() -> String:
	match rarity:
		Rarity.POCO_COMUN: return "Poco común"
		Rarity.RARO: return "Raro"
		Rarity.ANOMALO: return "Anómalo"
		_: return "Común"

static func format_stat(label: String, value: float) -> String:
	var hex := "88ff88" if value >= 0.0 else "ff8888"
	return "[color=#%s]%s: %+.0f[/color]" % [hex, label, value]

func get_stat_lines() -> Array[String]:
	return []
