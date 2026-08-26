extends Node2D

func _ready() -> void:
	# --- PRUEBA TEMPORAL ---
	var inv := $YSortRoot/Player/InventoryManager
	var backpack := load("res://resources/items/equipment/backpack_basic.tres")

	inv.add_item(backpack)
	print("Peso antes de equipar: ", inv.get_current_weight())

	# Buscamos la entrada que acabamos de agregar para poder "equiparla"
	var entry = null
	for e in inv.body_grid._placed:
		if e.data == backpack:
			entry = e
			break

	inv.equip_from_entry(entry)
	print("Peso después de equipar: ", inv.get_current_weight())
	print("¿Tengo mochila puesta?: ", inv.get_equipped("bag") != null)
	print("Slots de hotbar ahora: ", inv.get_hotbar_slot_count())

	var dropped = inv.drop_equipped_bag()
	print("¿Se soltó?: ", dropped != null)
	print("¿Tengo mochila puesta después de soltarla?: ", inv.get_equipped("bag") != null)
	print("Slots de hotbar de nuevo: ", inv.get_hotbar_slot_count())
	# --- fin de la prueba ---

	var player = $YSortRoot/Player
	var inventory = $YSortRoot/Player/InventoryManager
	var hotbar = $YSortRoot/Player/HotbarManager

	$ItemSpawner.init(player, inventory, hotbar)
