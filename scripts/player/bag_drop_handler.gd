extends Node

@onready var _inventory: InventoryManager = get_parent().get_node("InventoryManager")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_bag"):
		_inventory.drop_equipped_bag()
