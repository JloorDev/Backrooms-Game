extends Area2D
class_name PickupItem

@export var prompt_text: String = "Presiona E para recoger"
@export var full_inventory_text: String = "Inventario lleno"

@onready var prompt: Label   = $InteractPrompt
@onready var sprite: Sprite2D = $Sprite2D

var _player_inside: bool = false
var _player_ref: CharacterBody2D = null

const OUTLINE_SHADER := preload("res://shaders/pickup_outline.gdshader")

const FLOAT_AMPLITUDE: float = 3.0
const FLOAT_SPEED:     float = 2.0
var _float_time:   float = randf() * TAU
var _base_sprite_y: float = 0.0

var _prompt_tween:  Tween = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	prompt.text = prompt_text
	prompt.visible = false
	prompt.modulate.a = 0.0

	_base_sprite_y = sprite.position.y

	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	sprite.material = mat

func _process(delta: float) -> void:
	_float_time += delta * FLOAT_SPEED
	sprite.position.y = _base_sprite_y + sin(_float_time) * FLOAT_AMPLITUDE

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
	_show_prompt()
	sprite.material.set_shader_parameter("outline_enabled", true)

func _on_body_exited(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	_player_inside = false
	_player_ref = null
	_hide_prompt()
	sprite.material.set_shader_parameter("outline_enabled", false)

func _show_prompt() -> void:
	prompt.visible = true
	prompt.pivot_offset = prompt.size / 2.0
	prompt.scale = Vector2(0.8, 0.8)
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()
	_prompt_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_prompt_tween.tween_property(prompt, "modulate:a", 1.0, 0.15)
	_prompt_tween.parallel().tween_property(prompt, "scale", Vector2.ONE, 0.15)

func _hide_prompt() -> void:
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()
	_prompt_tween = create_tween()
	_prompt_tween.tween_property(prompt, "modulate:a", 0.0, 0.1)
	_prompt_tween.tween_callback(func(): prompt.visible = false)

func _try_pick_up() -> void:
	if _pick_up(_player_ref):
		_play_pickup_animation()
	else:
		prompt.text = full_inventory_text

## En vez de desaparecer de golpe (queue_free instantáneo), un poponcito
## rápido de achicarse+desvanecer -- mismo lenguaje visual que ya usamos
## en los paneles del HUD al cerrarse.
## - JloorDev
func _play_pickup_animation() -> void:
	set_process(false)  # que no siga flotando mientras se encoge
	_hide_prompt()
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2(0.4, 0.4), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)

func _pick_up(_player: CharacterBody2D) -> bool:
	push_warning("PickupItem: _pick_up() no implementado en %s" % get_script().resource_path)
	return false
