extends Node2D

func _ready() -> void:
	var player = $YSortRoot/Player
	var inventory = $YSortRoot/Player/InventoryManager
	$ItemSpawner.init(player, inventory)

	var ls_scene = load("res://prefabs/ui/loading_screen.tscn")
	var loading = ls_scene.instantiate()
	add_child(loading)
	$WorldManager.start_with_loading(loading)
