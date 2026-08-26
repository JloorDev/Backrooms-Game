extends Node
class_name InventoryManager

signal inventory_changed
signal item_dropped(data:ItemData)
signal weight_changed(current:float, max_weight:float)
signal weight_tier_changed(tier:WeightTier)
signal equipment_changed
signal bag_dropped(bag:EquippedBag, old_hotbar_slots:int, new_hotbar_slots:int)

enum WeightTier { NORMAL, OVERLOADED, CRITICAL }

const BODY_GRID_WIDTH:int = 4
const BODY_GRID_HEIGHT:int = 3
const BASE_HOTBAR_SLOTS:int = 3

const OVERLOAD_RATIO:float = 1.0   # 100% -- empieza penalización de velocidad/estamina
const CRITICAL_RATIO:float = 1.3   # 130% -- pierdes vida + no puedes recoger más

@export var base_max_weight:float = 30.0

var body_grid:ItemGrid = null

# equip_slot (String) -> EquippedBag
var equipped:Dictionary = {}

var _last_tier:WeightTier = WeightTier.NORMAL

func _ready() -> void:
	body_grid = ItemGrid.new(BODY_GRID_WIDTH, BODY_GRID_HEIGHT, base_max_weight)

# ── Inventario general (cuerpo) ───────────────────────────────────────────────

func add_item(data:ItemData, quantity:int = 1) -> bool:
	if get_weight_tier() == WeightTier.CRITICAL:
		return false
	if not body_grid.add_item(data, quantity):
		return false
	inventory_changed.emit()
	_emit_weight_signals()
	return true

func remove_item(entry:Dictionary) -> void:
	body_grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()

## Reduce en 1 la cantidad de una entrada -- si llega a 0, la quita del todo.
func consume_one(entry:Dictionary) -> void:
	entry.quantity -= 1
	if entry.quantity <= 0:
		body_grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()

func drop_entry(entry:Dictionary) -> void:
	body_grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()
	item_dropped.emit(entry.data)

# ── Peso y sus 3 niveles ───────────────────────────────────────────────────────

func get_current_weight() -> float:
	var total:float = body_grid.get_current_weight()
	if equipped.has("bag"):
		total += equipped["bag"].get_total_weight()
	return total

func get_max_weight() -> float:
	return base_max_weight

func get_weight_ratio() -> float:
	var max_w:float = get_max_weight()
	if max_w <= 0.0:
		return 0.0
	return get_current_weight() / max_w

func get_weight_tier() -> WeightTier:
	var ratio:float = get_weight_ratio()
	if ratio > CRITICAL_RATIO:
		return WeightTier.CRITICAL
	elif ratio > OVERLOAD_RATIO:
		return WeightTier.OVERLOADED
	return WeightTier.NORMAL

func _emit_weight_signals() -> void:
	weight_changed.emit(get_current_weight(), get_max_weight())
	var tier:WeightTier = get_weight_tier()
	if tier != _last_tier:
		_last_tier = tier
		weight_tier_changed.emit(tier)

# ── Equipo (mochilas/bolsos) ──────────────────────────────────────────────────

## Equipa una mochila que está en un slot del inventario general -- la saca
## de ahí (libera esas celdas) y la vuelve un contenedor propio.
## Si ya llevabas otra en esa misma categoría, se intenta devolver al
## inventario general; si no cabe, se suelta al piso.
func equip_from_entry(entry:Dictionary) -> void:
	var data:EquipmentData = entry.data
	body_grid.remove_item(entry)

	var previous:EquippedBag = equipped.get(data.equip_slot)
	var new_bag:EquippedBag = EquippedBag.new(data)
	equipped[data.equip_slot] = new_bag

	if previous != null:
		if not body_grid.add_item(previous.data):
			item_dropped.emit(previous.data)  # no cupo, se cae al piso

	inventory_changed.emit()
	equipment_changed.emit()
	_emit_weight_signals()

## Quita una mochila y la vuelve a poner en el inventario general (si cabe).
func unequip(equip_slot:String) -> bool:
	if not equipped.has(equip_slot):
		return false
	var bag:EquippedBag = equipped[equip_slot]
	if not body_grid.add_item(bag.data):
		return false  # no hay espacio -- se queda equipada
	equipped.erase(equip_slot)
	inventory_changed.emit()
	equipment_changed.emit()
	_emit_weight_signals()
	return true

func get_equipped(equip_slot:String) -> EquippedBag:
	return equipped.get(equip_slot)

func get_hotbar_slot_count() -> int:
	var bonus:int = 0
	if equipped.has("bag"):
		bonus = equipped["bag"].data.hotbar_slot_bonus
	return BASE_HOTBAR_SLOTS + bonus

## Mecánica de emergencia: suelta la mochila puesta CON su contenido intacto
## (recuperable después). Los slots de hotbar que dependían de ella se pierden.
func drop_equipped_bag() -> EquippedBag:
	if not equipped.has("bag"):
		return null

	var bag:EquippedBag = equipped["bag"]
	var old_hotbar_slots:int = get_hotbar_slot_count()
	equipped.erase("bag")
	var new_hotbar_slots:int = get_hotbar_slot_count()

	equipment_changed.emit()
	_emit_weight_signals()
	bag_dropped.emit(bag, old_hotbar_slots, new_hotbar_slots)

	return bag
