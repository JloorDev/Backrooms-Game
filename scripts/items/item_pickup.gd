extends PickupItem
class_name ItemPickup

@export var data: ItemData

func _pick_up(player: CharacterBody2D) -> bool:
	var inventory: InventoryManager = player.get_node("InventoryManager")
	return inventory.add_item(data)
