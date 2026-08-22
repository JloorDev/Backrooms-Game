extends Sprite2D

@onready var _stats: Node = get_parent().get_node("StatsManager")

func _ready() -> void:
	visible = not _stats.is_in_light
	_stats.light_exposure_changed.connect(_on_light_exposure_changed)

func _on_light_exposure_changed(in_light: bool) -> void:
	visible = not in_light
