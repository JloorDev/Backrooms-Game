extends Resource
class_name ItemData

@export var id:String = ""
@export var display_name:String = ""
@export var description:String = ""
@export var icon:Texture2D = null
@export var weight:float = 0.1
@export var max_stack:int = 1
@export var grid_width: int = 1
@export var grid_height: int = 1

func get_stat_lines() -> Array[String]:
	return []
