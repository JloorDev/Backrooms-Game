extends Node2D

func _ready() -> void:
	var player = $YSortRoot/Player
	var inventory = $YSortRoot/Player/InventoryManager
	var hotbar = $YSortRoot/Player/HotbarManager

	$ItemSpawner.init(player, inventory, hotbar)
