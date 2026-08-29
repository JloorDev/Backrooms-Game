extends Resource
class_name ItemData

enum Rarity { COMMON, UNCOMMON, RARE, ANOMALOUS }

@export var id:String = ""
@export var display_name:String = ""
@export var description:String = ""
@export var icon:Texture2D = null
@export var weight:float = 0.1
@export var max_stack:int = 1
@export var grid_width: int = 1
@export var grid_height: int = 1
@export var rarity: Rarity = Rarity.COMMON

func get_rarity_name() -> String:
	match rarity:
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.ANOMALOUS: return "Anomalous"
		_: return "Common"

static func format_stat(label: String, value: float) -> String:
	var hex := "88ff88" if value >= 0.0 else "ff8888"
	return "[color=#%s]%s: %+.0f[/color]" % [hex, label, value]

func get_stat_lines() -> Array[String]:
	return []
