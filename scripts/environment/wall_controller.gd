extends StaticBody2D

func _ready() -> void:
	var sprite: Sprite2D = $Sprite
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	add_to_group("shadow_receivers")
