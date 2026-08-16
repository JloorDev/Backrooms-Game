extends Panel

# ─────────────────────────────────────────
#  Panel arrastrable estilo PZ
#  Agrégalo como script a cualquier Panel
#  que quieras poder mover
# ─────────────────────────────────────────

@export var drag_handle_height: float = 24.0  # altura del área de arrastre (barra superior)
@export var clamp_to_screen:    bool  = true   # no salirse de la pantalla

var _dragging:  bool    = false
var _drag_offset: Vector2 = Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Solo arrastrar si el click es en la barra superior
				if event.position.y <= drag_handle_height:
					_dragging = true
					_drag_offset = global_position - get_global_mouse_position()
					# Traer al frente
					move_to_front()
			else:
				_dragging = false

	if event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() + _drag_offset
		if clamp_to_screen:
			var screen = get_viewport_rect().size
			new_pos.x = clampf(new_pos.x, 0.0, screen.x - size.x)
			new_pos.y = clampf(new_pos.y, 0.0, screen.y - size.y)
		global_position = new_pos

func _input(event: InputEvent) -> void:
	# Soltar si el mouse sale del área del panel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_dragging = false
