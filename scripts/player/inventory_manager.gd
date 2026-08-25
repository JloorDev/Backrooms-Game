extends Node
class_name InventoryManager

signal inventory_changed
signal item_dropped(data:ItemData)
signal weight_changed(current:float, max_weight:float)
signal equipment_changed
signal bag_dropped(bag:EquipmentData, old_hotbar_slots:int, new_hotbar_slots:int)

const SLOT_COUNT:int = 8
const BASE_HOTBAR_SLOTS:int = 3

@export var base_max_weight:float = 30.0

var slots:Array = []

var equipped:Dictionary = {}

func _ready() -> void:
	slots.resize(SLOT_COUNT)
	slots.fill(null)


func add_item(data:ItemData) -> bool:
	if data.max_stack > 1:
		for i in SLOT_COUNT:
			if slots[i] == null:
				continue
			if slots[i].data.id == data.id and slots[i].quantity < data.max_stack:
				slots[i].quantity += 1
				inventory_changed.emit()
				weight_changed.emit(get_current_weight(), get_max_weight())
				return true

	for i in SLOT_COUNT:
		if slots[i] == null:
			slots[i] = { "data": data, "quantity": 1 }
			inventory_changed.emit()
			weight_changed.emit(get_current_weight(), get_max_weight())
			return true

	return false

func consume_item_at(index:int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	if slots[index] == null:
		return
	slots[index].quantity -= 1
	if slots[index].quantity <= 0:
		slots[index] = null
	inventory_changed.emit()
	weight_changed.emit(get_current_weight(), get_max_weight())

func drop_item_at(index:int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	if slots[index] == null:
		return
	var dropped_data:ItemData = slots[index].data
	slots[index].quantity -= 1
	if slots[index].quantity <= 0:
		slots[index] = null
	inventory_changed.emit()
	weight_changed.emit(get_current_weight(), get_max_weight())
	item_dropped.emit(dropped_data)

func get_slot(index:int) -> Variant:
	return slots[index]

func get_current_weight() -> float:
	var total:float = 0.0
	for slot in slots:
		if slot != null:
			total += slot.data.weight * slot.quantity
	return total

func get_max_weight() -> float:
	var bonus:float = 0.0
	if equipped.has("bag"):
		bonus = equipped["bag"].weight_bonus
	return base_max_weight + bonus

func swap_slots(from:int, to:int) -> void:
	if from < 0 or from >= SLOT_COUNT:
		return
	if to < 0 or to >= SLOT_COUNT:
		return
	var temp = slots[to]
	slots[to]   = slots[from]
	slots[from] = temp
	inventory_changed.emit()
	weight_changed.emit(get_current_weight(), get_max_weight())

func equip_item(data:EquipmentData) -> EquipmentData:
	var previous:EquipmentData = equipped.get(data.equip_slot)
	equipped[data.equip_slot] = data
	equipment_changed.emit()
	weight_changed.emit(get_current_weight(), get_max_weight())
	return previous

func get_equipped(equip_slot:String) -> EquipmentData:
	return equipped.get(equip_slot)

func get_hotbar_slot_count() -> int:
	var bonus:int = 0
	if equipped.has("bag"):
		bonus = equipped["bag"].hotbar_slot_bonus
	return BASE_HOTBAR_SLOTS + bonus

func drop_equipped_bag() -> EquipmentData:
	if not equipped.has("bag"):
		return null

	var bag:EquipmentData = equipped["bag"]
	var old_hotbar_slots:int = get_hotbar_slot_count()
	equipped.erase("bag")
	var new_hotbar_slots:int = get_hotbar_slot_count()

	equipment_changed.emit()
	weight_changed.emit(get_current_weight(), get_max_weight())
	bag_dropped.emit(bag, old_hotbar_slots, new_hotbar_slots)

	return bag
