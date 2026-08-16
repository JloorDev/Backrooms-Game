extends Area2D
class_name AlmondWater

@export var data:ConsumableData = null

@onready var prompt:Label = $InteractPrompt

var _player_inside:bool = false
var _player_ref:CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false

func _unhandled_input(event:InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_on_interact()

func _on_body_entered(body:Node) -> void:
	if not body is CharacterBody2D:
		return
	_player_inside = true
	_player_ref = body
	prompt.visible = true

func _on_body_exited(body:Node) -> void:
	if not body is CharacterBody2D:
		return
	_player_inside = false
	_player_ref = null
	prompt.visible = false

func _on_interact() -> void:
	if data == null:
		push_warning("AlmondWater: no hay ConsumableData asignada.")
		return
	var inventory:InventoryManager = _player_ref.get_node("InventoryManager")
	var success:bool = inventory.add_item(data)
	if success:
		prompt.visible = false
		queue_free()
	else:
		prompt.text = "Inventario lleno"
