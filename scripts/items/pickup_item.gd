extends Area2D
class_name PickupItem

@export var prompt_text: String = "Presiona E para recoger"
@export var full_inventory_text: String = "Inventario lleno"

@onready var prompt: Label = $InteractPrompt

var _player_inside: bool = false
var _player_ref: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.text = prompt_text
	prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_try_pick_up()

func _on_body_entered(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	_player_inside = true
	_player_ref = body
	prompt.text = prompt_text
	prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	_player_inside = false
	_player_ref = null
	prompt.visible = false

func _try_pick_up() -> void:
	if _pick_up(_player_ref):
		prompt.visible = false
		queue_free()
	else:
		prompt.text = full_inventory_text

func _pick_up(_player: CharacterBody2D) -> bool:
	push_warning("PickupItem: _pick_up() no implementado en %s" % get_script().resource_path)
	return false
