extends PickupItem
class_name BagPickup

@export var data: EquipmentData = null

func _pick_up(player: CharacterBody2D) -> bool:
	if data == null:
		push_warning("BagPickup: no hay EquipmentData asignada.")
		return false

	var inventory: InventoryManager = player.get_node("InventoryManager")
	var previous: EquipmentData = inventory.equip_item(data)

	if previous != null:
		inventory.item_dropped.emit(previous)

	return true
