extends Panel
class_name InventorySlot

signal slot_selected
signal slot_context_requested(index:int, global_pos:Vector2)

@onready var texture_rect:TextureRect = $TextureRect
@onready var quantity_label:Label = $QuantityLabel

var slot_index:int = -1
var _inventory:InventoryManager = null

func init(index:int, inventory:InventoryManager) -> void:
	slot_index = index
	_inventory = inventory
	refresh()

func refresh() -> void:
	var slot = _inventory.get_slot(slot_index)
	if slot == null:
		texture_rect.texture = null
		quantity_label.visible = false
	else:
		texture_rect.texture = slot.data.icon
		quantity_label.visible = slot.quantity > 1
		quantity_label.text = "x%d" % slot.quantity

func _gui_input(event:InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			slot_selected.emit()
		MOUSE_BUTTON_RIGHT:
			var slot = _inventory.get_slot(slot_index)
			if slot != null:
				slot_context_requested.emit(slot_index, get_global_mouse_position())  # ← faltaba

func _get_drag_data(_pos:Vector2) -> Variant:
	var slot = _inventory.get_slot(slot_index)
	if slot == null:
		return null
	var preview:TextureRect = TextureRect.new()
	preview.texture = slot.data.icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	set_drag_preview(preview)
	return { "from_index": slot_index, "slot": slot }

func _can_drop_data(_pos:Vector2, data:Variant) -> bool:
	return data is Dictionary and data.has("from_index")

func _drop_data(_pos:Vector2, data:Variant) -> void:
	var from:int = data["from_index"]
	if from == slot_index:
		return
	_inventory.swap_slots(from, slot_index)
