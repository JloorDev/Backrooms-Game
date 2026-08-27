extends PickupItem
class_name DroppedBagPickup

## A diferencia de ItemPickup, esto no guarda un ItemData estático -- guarda
## el EquippedBag real que traía el jugador puesto, con su grilla interna y
## todo lo que tenía adentro, para no perderlo al recogerla de nuevo.
var bag:EquippedBag = null

func _pick_up(player:CharacterBody2D) -> bool:
	if bag == null:
		return false
	var inventory:InventoryManager = player.get_node("InventoryManager")
	inventory.equip_existing_bag(bag)
	return true
