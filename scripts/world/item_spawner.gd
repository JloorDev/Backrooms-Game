extends Node
class_name ItemSpawner

const ITEM_SCENES:Dictionary = {
	"almond_water": preload("res://prefabs/interactables/almond_water.tscn"),
	"backpack_basic": preload("res://prefabs/interactables/backpack_basic.tscn"),
}

const DROPPED_BAG_SCRIPT:Script = preload("res://scripts/items/pickups/dropped_bag_pickup.gd")

var _player:CharacterBody2D = null
var _inventory:InventoryManager = null

func init(player:CharacterBody2D, inventory:InventoryManager, hotbar:HotbarManager = null) -> void:
	_player = player
	_inventory = inventory
	_inventory.item_dropped.connect(_spawn_item)
	_inventory.bag_dropped.connect(_on_bag_dropped)
	if hotbar != null:
		hotbar.item_dropped.connect(_spawn_item)

## A diferencia de una mochila "nueva" (item_dropped -> _spawn_item), esta ya
## traía cosas adentro -- se instancia la misma escena visual, pero con el
## script cambiado por uno que recuerda su contenido y lo restaura al
## recogerla, en vez del pickup genérico que solo conoce el recurso .tres.
func _on_bag_dropped(bag:EquippedBag, _old_hotbar_slots:int, _new_hotbar_slots:int) -> void:
	if not ITEM_SCENES.has(bag.data.id):
		push_warning("ItemSpawner: no hay escena registrada para id '%s'" % bag.data.id)
		return
	var scene = ITEM_SCENES[bag.data.id]
	var instance = scene.instantiate()
	instance.set_script(DROPPED_BAG_SCRIPT)
	instance.bag = bag
	get_parent().add_child(instance)
	instance.global_position = _player.global_position + Vector2(24, 24)

func _spawn_item(data:ItemData) -> void:
	if not ITEM_SCENES.has(data.id):
		push_warning("ItemSpawner: no hay escena registrada para id '%s'" % data.id)
		return
	var scene = ITEM_SCENES[data.id]
	var instance = scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = _player.global_position + Vector2(24, 24)
