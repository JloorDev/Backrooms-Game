extends Node
class_name HotbarManager

signal hotbar_changed
signal item_dropped(data:ItemData)

# Cada slot es null o { data: ItemData, quantity: int } -- mismo formato
# que InventoryManager para reutilizar la misma UI de slot si hace falta.
var slots:Array = []

@onready var _inventory:InventoryManager = get_parent().get_node("InventoryManager")

func _ready() -> void:
	slots.resize(_inventory.get_hotbar_slot_count())
	slots.fill(null)
	_inventory.equipment_changed.connect(_on_equipment_changed)
	_inventory.bag_dropped.connect(_on_bag_dropped)

func add_item(data:ItemData, index:int = -1) -> bool:
	if index == -1:
		for i in slots.size():
			if slots[i] == null:
				slots[i] = { "data": data, "quantity": 1 }
				hotbar_changed.emit()
				return true
		return false

	if index < 0 or index >= slots.size():
		return false
	if slots[index] != null:
		return false

	slots[index] = { "data": data, "quantity": 1 }
	hotbar_changed.emit()
	return true

func remove_at(index:int) -> void:
	if index < 0 or index >= slots.size():
		return
	slots[index] = null
	hotbar_changed.emit()

func get_slot(index:int) -> Variant:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]

func swap_slots(from:int, to:int) -> void:
	if from < 0 or from >= slots.size():
		return
	if to < 0 or to >= slots.size():
		return
	var temp = slots[to]
	slots[to]   = slots[from]
	slots[from] = temp
	hotbar_changed.emit()

# ── Reacciona a cambios de equipo (mochila puesta/quitada) ───────────────────

func _on_equipment_changed() -> void:
	var new_count:int = _inventory.get_hotbar_slot_count()
	if new_count > slots.size():
		slots.resize(new_count)
		hotbar_changed.emit()

func _on_bag_dropped(_bag:EquipmentData, old_count:int, new_count:int) -> void:
	for i in range(new_count, old_count):
		if i < slots.size() and slots[i] != null:
			item_dropped.emit(slots[i].data)
	slots.resize(new_count)
	hotbar_changed.emit()
