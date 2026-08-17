extends Node2D

func _ready() -> void:
	var player = $YSortRoot/Player
	var inventory = $YSortRoot/Player/InventoryManager
	$ItemSpawner.init(player, inventory)
