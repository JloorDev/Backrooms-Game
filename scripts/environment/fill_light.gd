extends PointLight2D

@onready var _source: PointLight2D = get_parent()

func _process(_delta: float) -> void:
	energy = _source.energy
	color = _source.color
