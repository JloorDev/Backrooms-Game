extends PickupItem
class_name AlmondWater

@export var data: ConsumableData = null

func _pick_up(player: CharacterBody2D) -> bool:
	if data == null:
		push_warning("AlmondWater: no ConsumableData assigned.")
		return false
	var inventory: InventoryManager = player.get_node("InventoryManager")
	return inventory.add_item(data)
