extends Node

@export var vignette_shader: Shader = preload("res://shaders/vignette.gdshader")
@export var strength: float = 0.6
@export var radius: float = 0.75
@export var vignette_color: Color = Color(0.05, 0.04, 0.01, 1.0)

func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0, 0, 0, 0)

	var mat := ShaderMaterial.new()
	mat.shader = vignette_shader
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("radius", radius)
	mat.set_shader_parameter("vignette_color", vignette_color)
	rect.material = mat

	canvas.add_child(rect)
	_resize(rect)
	get_viewport().size_changed.connect(_resize.bind(rect))

func _resize(rect: ColorRect) -> void:
	rect.position = Vector2.ZERO
	rect.size = get_viewport().get_visible_rect().size
