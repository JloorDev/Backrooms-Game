extends Control
class_name ItemGridView

# Dibuja UNA grilla (ItemGrid) como cuadraditos clickeables -- no le importa
# si es el inventario del cuerpo o el interior de una mochila, por eso se
# usa dos veces en el HUD (InventoryPanel e BagPanel) con la misma escena.
# Recibe todo por init(): a qué InventoryManager avisarle de los cambios,
# qué grilla dibujar, y qué paneles cuentan como "zona de inventario" para
# lo de arrastrar-y-soltar-fuera-tira-el-ítem (ver _notification más abajo).
# - JloorDev

signal item_selected(entry: Dictionary)
signal item_context_requested(entry: Dictionary, global_pos: Vector2)
signal empty_clicked

@export var cell_size: int = 48
@export var cell_gap: int = 4

var _inventory: InventoryManager = null
var _grid: ItemGrid = null
var _bounds_controls: Array = []
var _cell_panels: Array = []
var _item_nodes: Array = []
var _highlight: Panel = null
var _selected_entry_ref: Variant = null

var _drop_highlight: Panel = null
var _dragging_entry: Variant = null

## inventory: para operaciones (drop_entry, move_entry_to_grid, etc).
## grid: la grilla que ESTA vista en particular debe dibujar -- puede ser
## _inventory.body_grid o el .grid interno de una mochila equipada.
## bounds_controls: los paneles que cuentan como "zona de inventario" -- si
## sueltas un ítem fuera de TODOS ellos, se tira al mundo. Pasa una lista
## porque ahora el inventario general y la mochila son paneles separados,
## y mover un ítem de uno a otro no debería contar como "tirarlo".
func init(inventory: InventoryManager, grid: ItemGrid, bounds_controls: Array = []) -> void:
	_inventory = inventory
	_grid = grid
	_bounds_controls = bounds_controls
	_build_cells()
	refresh()
	if not mouse_exited.is_connected(_clear_drop_highlight):
		mouse_exited.connect(_clear_drop_highlight)

func _build_cells() -> void:
	for child in get_children():
		child.queue_free()
	_cell_panels.clear()
	_item_nodes.clear()
	_highlight = null
	_drop_highlight = null

	var grid: ItemGrid = _grid

	custom_minimum_size = Vector2(
		grid.width * (cell_size + cell_gap) - cell_gap,
		grid.height * (cell_size + cell_gap) - cell_gap
	)

	for y in grid.height:
		for x in grid.width:
			var panel := Panel.new()
			panel.position = Vector2(x * (cell_size + cell_gap), y * (cell_size + cell_gap))
			panel.size = Vector2(cell_size, cell_size)
			panel.add_theme_stylebox_override("panel", _make_cell_style())
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(panel)
			_cell_panels.append(panel)

func _make_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.4, 0.8)
	return style

func refresh() -> void:
	for node in _item_nodes:
		node.queue_free()
	_item_nodes.clear()

	if _inventory == null or _grid == null:
		return

	var grid: ItemGrid = _grid
	for entry in grid._placed:
		_item_nodes.append(_create_item_node(entry))

	if _selected_entry_ref != null:
		set_selected(_selected_entry_ref)

func _create_item_node(entry: Dictionary) -> Control:
	var data: ItemData = entry.data

	var rect_size := _entry_pixel_size(entry)
	var rect_pos := _entry_pixel_pos(entry)

	var texture_rect := TextureRect.new()
	texture_rect.texture = data.icon
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.position = rect_pos
	texture_rect.size = rect_size
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	_item_nodes.append(texture_rect)

	if entry.quantity > 1:
		var label := Label.new()
		label.text = "x%d" % entry.quantity
		label.position = rect_pos + rect_size - Vector2(28, 18)
		label.size = Vector2(26, 16)
		label.add_theme_font_size_override("font_size", 12)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_item_nodes.append(label)

	return texture_rect

func _entry_pixel_size(entry: Dictionary) -> Vector2:
	var data: ItemData = entry.data
	return Vector2(
		data.grid_width  * (cell_size + cell_gap) - cell_gap,
		data.grid_height * (cell_size + cell_gap) - cell_gap
	)

func _entry_pixel_pos(entry: Dictionary) -> Vector2:
	var origin: Vector2i = entry.origin
	return Vector2(origin.x * (cell_size + cell_gap), origin.y * (cell_size + cell_gap))

func _rect_at(origin: Vector2i, size_cells: Vector2i) -> Rect2:
	return Rect2(
		Vector2(origin.x * (cell_size + cell_gap), origin.y * (cell_size + cell_gap)),
		Vector2(
			size_cells.x * (cell_size + cell_gap) - cell_gap,
			size_cells.y * (cell_size + cell_gap) - cell_gap
		)
	)

# ── Selección ──────────────────────────────────────────────────────────────

func set_selected(entry: Variant) -> void:
	_selected_entry_ref = entry
	if _highlight:
		_highlight.queue_free()
		_highlight = null
	if entry == null:
		return

	_highlight = Panel.new()
	_highlight.position = _entry_pixel_pos(entry)
	_highlight.size = _entry_pixel_size(entry)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.6, 1.0, 0.25)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.6, 1.0, 0.9)
	_highlight.add_theme_stylebox_override("panel", style)
	add_child(_highlight)

# ── Input (clic / menú contextual) ──────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var cell = _pixel_to_cell(event.position)
	if cell == null:
		return

	var entry = _grid.get_entry_at(cell.x, cell.y)

	if event.button_index == MOUSE_BUTTON_LEFT:
		if entry != null:
			item_selected.emit(entry)
		else:
			empty_clicked.emit()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if entry != null:
			item_context_requested.emit(entry, get_global_mouse_position())

func _pixel_to_cell(local_pos: Vector2) -> Variant:
	var grid: ItemGrid = _grid
	var cx := int(local_pos.x / (cell_size + cell_gap))
	var cy := int(local_pos.y / (cell_size + cell_gap))
	if cx < 0 or cy < 0 or cx >= grid.width or cy >= grid.height:
		return null
	return Vector2i(cx, cy)

# ── Arrastrar y soltar ───────────────────────────────────────────────────────

func _get_drag_data(at_position: Vector2) -> Variant:
	var cell = _pixel_to_cell(at_position)
	if cell == null:
		return null
	var entry = _grid.get_entry_at(cell.x, cell.y)
	if entry == null:
		return null

	_dragging_entry = entry

	var preview := TextureRect.new()
	preview.texture = entry.data.icon
	preview.custom_minimum_size = _entry_pixel_size(entry)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return { "entry": entry }

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or not data.has("entry"):
		_clear_drop_highlight()
		return false

	var entry: Dictionary = data["entry"]
	var origin = _pixel_to_cell(at_position)
	if origin == null:
		_clear_drop_highlight()
		return false

	var cell_span := Vector2i(entry.data.grid_width, entry.data.grid_height)
	var valid: bool
	if entry.grid == _grid:
		valid = _grid.can_place_at_ignoring(entry.data, origin, entry)
	else:
		valid = _grid.can_place_at(entry.data, origin)
	_show_drop_highlight(origin, cell_span, valid)
	return valid

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var entry: Dictionary = data["entry"]
	var origin = _pixel_to_cell(at_position)
	_clear_drop_highlight()
	if origin == null:
		return
	_inventory.move_entry_to_grid(entry, _grid, origin)
	refresh()

## Godot avisa a todo el árbol cuando termina un arrastre. Si el arrastre
## que empezamos nosotros no fue aceptado por nadie (gui_is_drag_successful
## == false) Y el mouse quedó fuera del panel de inventario, el jugador
## soltó el ítem -- se comporta como tirarlo al piso.
func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return
	if _dragging_entry == null:
		return

	if not get_viewport().gui_is_drag_successful():
		var outside_all: bool = true
		for c in _bounds_controls:
			if c != null and c.visible and c.get_global_rect().has_point(get_global_mouse_position()):
				outside_all = false
				break
		if outside_all:
			_inventory.drop_entry(_dragging_entry)

	_dragging_entry = null

func _show_drop_highlight(origin: Vector2i, size_cells: Vector2i, valid: bool) -> void:
	if _drop_highlight == null:
		_drop_highlight = Panel.new()
		_drop_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_drop_highlight)

	var rect := _rect_at(origin, size_cells)
	_drop_highlight.position = rect.position
	_drop_highlight.size = rect.size

	var style := StyleBoxFlat.new()
	if valid:
		style.bg_color = Color(0.25, 0.8, 0.3, 0.35)
		style.border_color = Color(0.25, 0.8, 0.3, 0.9)
	else:
		style.bg_color = Color(0.85, 0.2, 0.2, 0.35)
		style.border_color = Color(0.85, 0.2, 0.2, 0.9)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	_drop_highlight.add_theme_stylebox_override("panel", style)

func _clear_drop_highlight() -> void:
	if _drop_highlight:
		_drop_highlight.queue_free()
		_drop_highlight = null
