extends Node
class_name InventoryManager

# El dueño de todo lo relacionado a qué cargas. body_grid es el inventario
# general (lo que llevas encima, sin mochila), y "equipped" son las cosas
# que tienes puestas -- por ahora solo el slot "bag", pero está pensado
# como diccionario por si en algún momento hay más de un slot de equipo.
#
# Ojo con esto: un ítem colocado en una grilla se acuerda solo de a qué
# grilla pertenece (entry.grid, lo pone ItemGrid.place_item). Por eso
# remove_item/consume_one/drop_entry no necesitan que les digas "de dónde"
# sacar el ítem -- funcionan igual si está en el cuerpo o adentro de la
# mochila equipada.
# - JloorDev

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
	entry.grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()

## Reduce en 1 la cantidad de una entrada -- si llega a 0, la quita del todo.
func consume_one(entry:Dictionary) -> void:
	entry.quantity -= 1
	if entry.quantity <= 0:
		entry.grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()

## Saca una entrada de la grilla en la que esté (cuerpo o mochila) y la suelta
## en el mundo -- se usa tanto para el botón "Soltar" del menú contextual como
## para cuando arrastras un ítem fuera del panel de inventario.
func drop_entry(entry:Dictionary) -> void:
	entry.grid.remove_item(entry)
	inventory_changed.emit()
	_emit_weight_signals()
	item_dropped.emit(entry.data)

## Mueve una entrada ya colocada hacia otra celda -- puede ser dentro de la
## misma grilla (reordenar) o hacia una grilla distinta (ej: del cuerpo a la
## mochila equipada, o viceversa). Devuelve false si no cupo en el destino.
func move_entry_to_grid(entry:Dictionary, to_grid:ItemGrid, new_origin:Vector2i) -> bool:
	var from_grid:ItemGrid = entry.grid
	if from_grid == to_grid:
		return from_grid.move_item(entry, new_origin)

	if not to_grid.can_place_at(entry.data, new_origin):
		return false

	from_grid.remove_item(entry)
	to_grid.place_item(entry.data, new_origin, entry.quantity)
	inventory_changed.emit()
	_emit_weight_signals()
	return true

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
	entry.grid.remove_item(entry)

	var previous:EquippedBag = equipped.get(data.equip_slot)
	var new_bag:EquippedBag = EquippedBag.new(data)
	equipped[data.equip_slot] = new_bag

	if previous != null:
		if not body_grid.add_item(previous.data):
			item_dropped.emit(previous.data)  # no cupo, se cae al piso

	inventory_changed.emit()
	equipment_changed.emit()
	_emit_weight_signals()

## Vuelve a equipar una mochila que ya existía CON su contenido -- se usa al
## recoger del piso una mochila que se había soltado con ítems adentro, para
## no perderlos. A diferencia de equip_from_entry, no crea un EquippedBag
## nuevo y vacío: reutiliza el mismo objeto (y su grilla interna) tal cual
## estaba antes de soltarla.
func equip_existing_bag(bag:EquippedBag) -> void:
	var previous:EquippedBag = equipped.get(bag.data.equip_slot)
	equipped[bag.data.equip_slot] = bag

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
