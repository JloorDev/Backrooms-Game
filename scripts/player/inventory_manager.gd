extends Node
class_name InventoryManager

signal inventory_changed
signal item_dropped(data:ItemData)
signal weight_changed(current:float, max_weight:float)

const SLOT_COUNT:int = 16

@export var base_max_weight:float = 30.0

# Cada slot es null o { data: ItemData, quantity: int }
var slots:Array = []

func _ready() -> void:
	slots.resize(SLOT_COUNT)
	slots.fill(null)

# ── API pública ──────────────────────────────────────────────────────────────

func add_item(data:ItemData) -> bool:
	# Intenta apilar primero
	if data.max_stack > 1:
		for i in SLOT_COUNT:
			if slots[i] == null:
				continue
			if slots[i].data.id == data.id and slots[i].quantity < data.max_stack:
				slots[i].quantity += 1
				inventory_changed.emit()
				weight_changed.emit(get_current_weight(), get_max_weight())
				return true

	# Busca slot vacío
	for i in SLOT_COUNT:
		if slots[i] == null:
			slots[i] = { "data": data, "quantity": 1 }
			inventory_changed.emit()
			weight_changed.emit(get_current_weight(), get_max_weight())
			return true

	return false  # inventario lleno

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
	return base_max_weight

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
