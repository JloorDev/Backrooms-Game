extends Node2D

func _ready() -> void:
	var player = $Player
	var inventory = $Player/InventoryManager
	$ItemSpawner.init(player, inventory)
