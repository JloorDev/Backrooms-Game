extends Node
class_name ItemSpawner

# Registra aquí cada id de item con su escena correspondiente
const ITEM_SCENES:Dictionary = {
	"almond_water": preload("res://prefabs/interactables/almond_water.tscn"),
}

var _player:CharacterBody2D = null
var _inventory:InventoryManager = null

func init(player:CharacterBody2D, inventory:InventoryManager) -> void:
	_player = player
	_inventory = inventory
	_inventory.item_dropped.connect(_on_item_dropped)

func _on_item_dropped(data:ItemData) -> void:
	if not ITEM_SCENES.has(data.id):
		push_warning("ItemSpawner: no hay escena registrada para id '%s'" % data.id)
		return
	var scene = ITEM_SCENES[data.id]
	var instance = scene.instantiate()
	# Lo instancia como hijo del nivel (el padre del ItemSpawner)
	get_parent().add_child(instance)
	# Lo coloca frente al jugador con un pequeño offset
	instance.global_position = _player.global_position + Vector2(24, 24)
