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

# Popup animado en vez de aparecer/desaparecer de golpe: achica+desvanece un
# poco y crece de vuelta a su tamaño normal con un empujoncito al final
# (TRANS_BACK). Guardamos el tween activo para poder cortarlo si el jugador
# hace click varias veces rápido y no se pisen dos animaciones a la vez.
# - JloorDev
signal opened
signal closed

const _POPUP_DURATION: float = 0.16
var _popup_tween: Tween = null

func open() -> void:
	if _popup_tween:
		_popup_tween.kill()
	pivot_offset = size / 2.0
	visible = true
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	_popup_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_popup_tween.tween_property(self, "scale", Vector2.ONE, _POPUP_DURATION)
	_popup_tween.parallel().tween_property(self, "modulate:a", 1.0, _POPUP_DURATION)
	_popup_tween.tween_callback(opened.emit)

func close() -> void:
	if not visible:
		return
	if _popup_tween:
		_popup_tween.kill()
	pivot_offset = size / 2.0
	_popup_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_popup_tween.tween_property(self, "scale", Vector2(0.85, 0.85), _POPUP_DURATION * 0.75)
	_popup_tween.parallel().tween_property(self, "modulate:a", 0.0, _POPUP_DURATION * 0.75)
	_popup_tween.tween_callback(func():
		visible = false
		closed.emit()
	)

func toggle() -> void:
	if visible:
		close()
	else:
		open()

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
