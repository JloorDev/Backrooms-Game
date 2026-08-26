extends Node
class_name ItemSpawner

const ITEM_SCENES:Dictionary = {
	"almond_water": preload("res://prefabs/interactables/almond_water.tscn"),
	"backpack_basic": preload("res://prefabs/interactables/backpack_basic.tscn"),
}

var _player:CharacterBody2D = null
var _inventory:InventoryManager = null

func init(player:CharacterBody2D, inventory:InventoryManager, hotbar:HotbarManager = null) -> void:
	_player = player
	_inventory = inventory
	_inventory.item_dropped.connect(_spawn_item)
	_inventory.bag_dropped.connect(_on_bag_dropped)
	if hotbar != null:
		hotbar.item_dropped.connect(_spawn_item)

func _on_bag_dropped(bag:EquippedBag, _old_hotbar_slots:int, _new_hotbar_slots:int) -> void:
	# TODO: preservar el contenido real de bag.grid al volver a instanciarla
	# en el mundo -- por ahora solo recreamos el objeto vacio (bag.data).
	_spawn_item(bag.data)

func _spawn_item(data:ItemData) -> void:
	if not ITEM_SCENES.has(data.id):
		push_warning("ItemSpawner: no hay escena registrada para id '%s'" % data.id)
		return
	var scene = ITEM_SCENES[data.id]
	var instance = scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = _player.global_position + Vector2(24, 24)
