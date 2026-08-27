extends CanvasLayer
class_name HUD

# Todo lo de acá abajo usa "%NombreDelNodo" en vez de "$Panel/Cajita/Nodo".
# Es el sistema de nombres únicos de Godot: le pones "Access as Unique Name"
# a un nodo en el editor (click derecho en el árbol de la escena) y después
# lo encontrás por su nombre sin importar dónde esté colgado. La ventaja es
# que si más adelante querés reordenar el HUD -- meter cosas en carpetas,
# agrupar paneles distinto, lo que sea -- lo hacés arrastrando en el editor
# y este script ni se entera, sigue encontrando todo igual.
# - JloorDev

@onready var health_bar:  ProgressBar = %HealthProgressBar
@onready var stamina_bar: ProgressBar = %StaminaProgressBar
@onready var thirst_bar:  ProgressBar = %ThirstProgressBar
@onready var hunger_bar:  ProgressBar = %HungerProgressBar
@onready var sanity_bar:  ProgressBar = %SanityProgressBar

@onready var stats_panel:      Panel         = %StatsPanel
@onready var inventory_panel:  Panel         = %InventoryPanel
@onready var player_panel:     Panel         = %PlayerPanel
@onready var quick_bar:        VBoxContainer = %QuickBar
@onready var quickbar_hover_zone: Control    = %QuickBarHoverZone
@onready var states_container: VBoxContainer = %StatesContainer

@onready var btn_stats:     Button = %BtnStats
@onready var btn_inventory: Button = %BtnInventory
@onready var btn_player:    Button = %BtnPlayer

@onready var grid_view:        ItemGridView = %ItemGridView
@onready var weight_label:     Label        = %WeightLabel
@onready var item_name_label:  Label        = %ItemNameLabel
@onready var item_desc_label:  Label        = %ItemDescLabel
@onready var item_stats_label: Label        = %ItemStatsLabel
@onready var equipped_bag_icon:  TextureRect = %EquippedBagIcon
@onready var equipped_bag_label: Label       = %EquippedBagLabel
@onready var drop_bag_button:    Button      = %DropBagButton
@onready var open_bag_button:    Button      = %OpenBagButton
@onready var use_button:      Button = %UseButton
@onready var context_menu:    Panel  = %ContextMenu

# Ojo con estos tres: hay OTRO botón "Use" en el panel de info del ítem
# (arriba, use_button) y este de acá es el del menú contextual (click
# derecho sobre un ítem). Por eso los nombré con prefijo "Ctx" en la
# escena -- antes los dos se llamaban igual y prestaba a confundirse.
# - JloorDev
@onready var ctx_use:   Button = %CtxUseButton
@onready var ctx_drop:  Button = %CtxDropButton
@onready var ctx_equip: Button = %CtxEquipButton

@onready var bag_panel:        Panel        = %BagPanel
@onready var bag_grid_view:    ItemGridView = %BagGridView
@onready var bag_weight_label: Label        = %BagWeightLabel

const COLOR_HIGH: Color = Color(0.20, 0.75, 0.25)
const COLOR_MID:  Color = Color(0.90, 0.70, 0.10)
const COLOR_LOW:  Color = Color(0.85, 0.25, 0.10)

var _target:  Dictionary = {"health":100.0,"stamina":100.0,"thirst":100.0,"hunger":100.0,"sanity":100.0}
var _current: Dictionary = {"health":100.0,"stamina":100.0,"thirst":100.0,"hunger":100.0,"sanity":100.0}
const SMOOTH_SPEED: float = 60.0

const ANIM_DURATION:  float = 0.25
const QUICKBAR_SHOWN_X:  float = 10.0

# La barra siempre está a la vista -- el jugador no tiene forma de adivinar
# que hay que pasar el mouse por una esquina, así que replegarla del todo
# quedó descartado. Lo único que hace el hover ahora es atenuarla un poco
# cuando no la estás usando, para que estorbe menos visualmente.
#
# Dos condiciones tienen que darse a la vez para que se atenúe:
#   1. el mouse no está sobre la zona (QuickBarHoverZone), Y
#   2. no hay ningún panel abierto (si estás revisando el inventario, por
#      ejemplo, no tiene sentido que la barra se desvanezca de fondo).
# Apenas deja de cumplirse cualquiera de las dos, vuelve a opacidad completa.
#
# "_quickbar_hover_token" cancela una espera vieja si algo cambió mientras
# esperábamos: sube en 1 cada vez que se llama _update_quickbar_dim(), y al
# terminar el await se compara -- si ya no coincide, alguien más reciente
# (el mouse volvió, se abrió un panel) ya decidió otra cosa, así que no hacemos nada.
# - JloorDev
const QUICKBAR_DIM_DELAY: float = 0.35
const QUICKBAR_DIM_ALPHA: float = 0.3

var _mouse_in_quickbar_zone: bool = false
var _quickbar_tween: Tween = null
var _quickbar_hover_token: int = 0

func _any_panel_open() -> bool:
	return stats_panel.visible or inventory_panel.visible or player_panel.visible or bag_panel.visible

func _update_quickbar_dim() -> void:
	_quickbar_hover_token += 1
	if _mouse_in_quickbar_zone or _any_panel_open():
		_set_quickbar_alpha(1.0)
	else:
		_wait_and_dim_quickbar(_quickbar_hover_token)

func _set_quickbar_alpha(target: float) -> void:
	if _quickbar_tween and _quickbar_tween.is_valid():
		_quickbar_tween.kill()
	_quickbar_tween = create_tween()
	_quickbar_tween.tween_property(quick_bar, "modulate:a", target, ANIM_DURATION)

func _wait_and_dim_quickbar(token: int) -> void:
	await get_tree().create_timer(QUICKBAR_DIM_DELAY).timeout
	if token != _quickbar_hover_token:
		return  # algo más reciente ya decidió el estado -- no pisarlo
	_set_quickbar_alpha(QUICKBAR_DIM_ALPHA)

# En vez de mouse_entered/mouse_exited de la zona (que Godot le quita a este
# Control apenas el mouse pasa sobre CUALQUIER otro nodo dibujado encima,
# como los propios botones -- por eso parpadeaba), preguntamos nosotros
# mismos cada cuadro si el punto del mouse cae dentro del rectángulo de la
# zona. Es una comprobación geométrica pura, no depende de qué nodo esté
# "arriba" en ese pixel.
# - JloorDev
func _check_quickbar_hover() -> void:
	var is_inside: bool = quickbar_hover_zone.get_global_rect().has_point(quickbar_hover_zone.get_global_mouse_position())
	if is_inside == _mouse_in_quickbar_zone:
		return
	_mouse_in_quickbar_zone = is_inside
	_update_quickbar_dim()

var _stats:     StatsManager       = null
var _inventory: InventoryManager   = null
var _psm:       PlayerStateManager = null

var _selected_entry: Variant = null
var _context_entry: Variant = null

const SLOT_SCENE = preload("res://prefabs/ui/inventory_slot.tscn")

@onready var hotbar_container: HBoxContainer = %Hotbar

var _hotbar: HotbarManager = null
var _hotbar_slot_nodes: Array[InventorySlot] = []

# Todo esto arranca desde PlayerMovement._ready(), que llama a este init()
# pasándole los managers reales del jugador (stats, inventario, etc). De
# ahí para abajo, cada _refresh_x()/_build_x() se encarga de una sola
# sección del HUD y se vuelve a llamar solo cuando la señal que le importa
# cambia -- no hay ningún _process() recalculando cosas que no cambiaron.
# - JloorDev
func init(stats: StatsManager, inventory: InventoryManager, psm: PlayerStateManager = null, hotbar: HotbarManager = null) -> void:
	_stats     = stats
	_inventory = inventory
	_psm       = psm
	_hotbar    = hotbar
	_build_grid()
	_build_hotbar()
	_connect_signals()
	_refresh_all()
	_refresh_equipped_bag()

	stats_panel.visible    = false
	inventory_panel.visible = false
	player_panel.visible   = false
	bag_panel.visible      = false

	quick_bar.position.x = QUICKBAR_SHOWN_X
	quick_bar.modulate.a = 1.0

	_update_quickbar_dim()

func _process(delta: float) -> void:
	_animate_bars(delta)
	_check_quickbar_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and context_menu.visible:
			_close_context()

func _toggle_stats() -> void:
	stats_panel.toggle()

func _toggle_inventory() -> void:
	var opening: bool = not inventory_panel.visible
	inventory_panel.toggle()
	if not opening and bag_panel.visible:
		# no tiene sentido dejar la mochila abierta sola si cerraste el
		# inventario general -- se cierra junto con él.
		bag_panel.close()
		open_bag_button.text = "Abrir mochila"
	_close_context()
	_selected_entry = null
	_clear_all_selections()
	_refresh_item_info()

func _toggle_player_panel() -> void:
	var opening: bool = not player_panel.visible
	player_panel.toggle()
	if opening and _psm:
		_refresh_states_panel(_psm.get_active_states())

# ─────────────────────────────────────────
#  Animación barras
# ─────────────────────────────────────────
func _animate_bars(delta: float) -> void:
	var speed = SMOOTH_SPEED * delta
	for key in _target.keys():
		_current[key] = move_toward(_current[key], _target[key], speed)

	health_bar.value  = _current["health"]
	stamina_bar.value = _current["stamina"]
	thirst_bar.value  = _current["thirst"]
	hunger_bar.value  = _current["hunger"]
	sanity_bar.value  = _current["sanity"]

	_update_bar_color(health_bar,  _current["health"])
	_update_bar_color(stamina_bar, _current["stamina"])
	_update_bar_color(thirst_bar,  _current["thirst"])
	_update_bar_color(hunger_bar,  _current["hunger"])
	_update_bar_color(sanity_bar,  _current["sanity"])

func _update_bar_color(bar: ProgressBar, value: float) -> void:
	var color: Color
	if value > 60.0:
		color = COLOR_HIGH.lerp(COLOR_MID, (100.0 - value) / 40.0)
	elif value > 25.0:
		color = COLOR_MID.lerp(COLOR_LOW, (60.0 - value) / 35.0)
	else:
		color = COLOR_LOW
	bar.add_theme_color_override("fill_color", color)

# ─────────────────────────────────────────
#  Señales stats
# ─────────────────────────────────────────
func _connect_signals() -> void:
	_stats.health_changed.connect(_on_health_changed)
	_stats.stamina_changed.connect(_on_stamina_changed)
	_stats.hunger.hunger_changed.connect(_on_hunger_changed)
	_stats.thirst.thirst_changed.connect(_on_thirst_changed)
	_stats.sanity.sanity_changed.connect(_on_sanity_changed)
	_inventory.inventory_changed.connect(_refresh_grid)
	_inventory.weight_changed.connect(_on_weight_changed)
	_inventory.weight_tier_changed.connect(_on_weight_tier_changed)
	_inventory.equipment_changed.connect(_refresh_equipped_bag)
	drop_bag_button.pressed.connect(_on_drop_bag_pressed)
	open_bag_button.pressed.connect(_toggle_bag_panel)
	grid_view.item_selected.connect(_on_grid_item_selected)
	grid_view.item_context_requested.connect(_on_grid_item_context)
	grid_view.empty_clicked.connect(_on_grid_empty_clicked)
	bag_grid_view.item_selected.connect(_on_grid_item_selected)
	bag_grid_view.item_context_requested.connect(_on_grid_item_context)
	bag_grid_view.empty_clicked.connect(_on_grid_empty_clicked)
	use_button.pressed.connect(_on_use_pressed)
	ctx_use.pressed.connect(_on_ctx_use)
	ctx_drop.pressed.connect(_on_ctx_drop)
	ctx_equip.pressed.connect(_on_ctx_equip)
	btn_stats.pressed.connect(_toggle_stats)
	btn_inventory.pressed.connect(_toggle_inventory)
	btn_player.pressed.connect(_toggle_player_panel)

	for panel in [stats_panel, inventory_panel, player_panel, bag_panel]:
		panel.opened.connect(_update_quickbar_dim)
		panel.closed.connect(_update_quickbar_dim)

	if _psm:
		_psm.states_changed.connect(_on_states_changed)
	if _hotbar:
		_hotbar.hotbar_changed.connect(_refresh_hotbar)

func _refresh_equipped_bag() -> void:
	var bag: EquippedBag = _inventory.get_equipped("bag")
	if bag == null:
		equipped_bag_icon.texture = null
		equipped_bag_label.text = "Sin mochila"
		drop_bag_button.visible = false
		open_bag_button.visible = false
		open_bag_button.text = "Abrir mochila"
		bag_panel.visible = false  # de golpe, no con animación: ya no hay mochila que mostrar
		_update_quickbar_dim()  # bag_panel.visible cambió sin pasar por close(), así que esto no se enteró solo
	else:
		equipped_bag_icon.texture = bag.data.icon
		equipped_bag_label.text = bag.data.display_name
		drop_bag_button.visible = true
		open_bag_button.visible = true
		if bag_panel.visible:
			bag_grid_view.init(_inventory, bag.grid, [inventory_panel, bag_panel])
			_refresh_bag_weight_label()

func _toggle_bag_panel() -> void:
	var bag: EquippedBag = _inventory.get_equipped("bag")
	if bag == null:
		return
	var opening: bool = not bag_panel.visible
	bag_panel.toggle()
	open_bag_button.text = "Cerrar mochila" if opening else "Abrir mochila"
	if opening:
		bag_grid_view.init(_inventory, bag.grid, [inventory_panel, bag_panel])
		_refresh_bag_weight_label()

## Muestra cuánto espacio (peso interno) lleva usado la mochila -- esto es
## el límite propio de la mochila (internal_max_weight), sin el descuento
## de external_weight_multiplier: es "cuánto le cabe", no "cuánto se nota
## en el peso del jugador".
func _refresh_bag_weight_label() -> void:
	var bag: EquippedBag = _inventory.get_equipped("bag")
	if bag == null:
		return
	bag_weight_label.text = "Espacio: %.1f / %.1f kg" % [bag.grid.get_current_weight(), bag.grid.max_weight]

func _on_drop_bag_pressed() -> void:
	_inventory.drop_equipped_bag()

func _refresh_all() -> void:
	_target["health"]  = (_stats.health  / _stats.max_health)  * 100.0
	_target["stamina"] = (_stats.stamina / _stats.max_stamina) * 100.0
	_target["hunger"]  = _stats.hunger.get_percent() * 100.0
	_target["thirst"]  = _stats.thirst.get_percent() * 100.0
	_target["sanity"]  = _stats.sanity.get_percent()  * 100.0
	_refresh_grid()

func _on_health_changed(_v: float, pct: float)  -> void: _target["health"]  = pct * 100.0
func _on_stamina_changed(_v: float, pct: float) -> void: _target["stamina"] = pct * 100.0
func _on_hunger_changed(_v: float, pct: float)  -> void: _target["hunger"]  = pct * 100.0
func _on_thirst_changed(_v: float, pct: float)  -> void: _target["thirst"]  = pct * 100.0
func _on_sanity_changed(_v: float, pct: float)  -> void: _target["sanity"]  = pct * 100.0

func _on_states_changed(active_states: Array) -> void:
	if not player_panel.visible:
		return
	_refresh_states_panel(active_states)

func _refresh_states_panel(active_states: Array) -> void:
	for child in states_container.get_children():
		child.queue_free()
	for s in active_states:
		var name_str = PlayerStateManager.STATE_NAMES.get(s, "?")
		var has_penalty = PlayerStateManager.STATE_PENALTIES.has(s) \
			and not PlayerStateManager.STATE_PENALTIES[s].is_empty()
		var label = Label.new()
		label.text = ("⚠ " if has_penalty else "✓ ") + name_str
		if has_penalty:
			var p = PlayerStateManager.STATE_PENALTIES[s]
			var severity = abs(p.get("speed", 0.0)) + p.get("sanity_drain", 0.0)
			label.add_theme_color_override("font_color",
				Color(0.9, 0.2, 0.1) if severity > 0.15 else Color(0.9, 0.7, 0.1))
		else:
			label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4))
		label.add_theme_font_size_override("font_size", 13)
		states_container.add_child(label)

func _build_hotbar() -> void:
	if _hotbar == null:
		return
	for child in hotbar_container.get_children():
		child.queue_free()
	_hotbar_slot_nodes.clear()
	for i in _hotbar.slots.size():
		var slot_node: InventorySlot = SLOT_SCENE.instantiate()
		hotbar_container.add_child(slot_node)
		slot_node.init(i, _hotbar)
		_hotbar_slot_nodes.append(slot_node)

func _refresh_hotbar() -> void:
	if _hotbar == null:
		return
	# El numero de slots puede crecer/encogerse (mochila puesta/quitada)
	if _hotbar_slot_nodes.size() != _hotbar.slots.size():
		_build_hotbar()
		return
	for slot_node in _hotbar_slot_nodes:
		slot_node.refresh()

func _build_grid() -> void:
	grid_view.init(_inventory, _inventory.body_grid, [inventory_panel, bag_panel])

func _refresh_grid() -> void:
	grid_view.refresh()
	if bag_panel.visible:
		bag_grid_view.refresh()
		_refresh_bag_weight_label()

func _on_weight_changed(current: float, max_w: float) -> void:
	var suffix := ""
	match _inventory.get_weight_tier():
		InventoryManager.WeightTier.CRITICAL:
			suffix = " -- ¡SOBRECARGA CRÍTICA!"
		InventoryManager.WeightTier.OVERLOADED:
			suffix = " -- Sobrecargado"
	weight_label.text = "Peso: %.1f / %.1f kg%s" % [current, max_w, suffix]

func _on_weight_tier_changed(tier: InventoryManager.WeightTier) -> void:
	match tier:
		InventoryManager.WeightTier.CRITICAL:
			weight_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		InventoryManager.WeightTier.OVERLOADED:
			weight_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.15))
		InventoryManager.WeightTier.NORMAL:
			weight_label.remove_theme_color_override("font_color")

func _grid_view_for(grid: ItemGrid) -> ItemGridView:
	if grid == _inventory.body_grid:
		return grid_view
	return bag_grid_view

func _clear_all_selections() -> void:
	grid_view.set_selected(null)
	bag_grid_view.set_selected(null)

func _on_grid_item_selected(entry: Dictionary) -> void:
	_selected_entry = entry
	_clear_all_selections()
	_grid_view_for(entry.grid).set_selected(entry)
	_refresh_item_info()

func _on_grid_empty_clicked() -> void:
	_selected_entry = null
	_clear_all_selections()
	_refresh_item_info()

func _refresh_item_info() -> void:
	if _selected_entry == null:
		item_name_label.text = ""
		item_desc_label.text = ""
		item_stats_label.text = ""
		use_button.visible   = false
		return
	var data: ItemData = _selected_entry.data
	item_name_label.text = data.display_name
	item_desc_label.text = data.description
	item_stats_label.text = "
".join(data.get_stat_lines())
	use_button.visible   = data is ConsumableData

func _on_use_pressed() -> void:
	if _selected_entry == null:
		return
	var data: ItemData = _selected_entry.data
	if data is ConsumableData:
		_stats.use_consumable(data)
		_inventory.consume_one(_selected_entry)
		_selected_entry = null
		_clear_all_selections()
		_refresh_item_info()

func _on_grid_item_context(entry: Dictionary, global_pos: Vector2) -> void:
	_context_entry = entry
	context_menu.global_position = global_pos
	context_menu.visible = true
	ctx_use.visible = entry.data is ConsumableData
	ctx_equip.visible = entry.data is EquipmentData

func _on_ctx_use() -> void:
	if _context_entry != null and _context_entry.data is ConsumableData:
		_stats.use_consumable(_context_entry.data)
		_inventory.consume_one(_context_entry)
		_selected_entry = null
		_clear_all_selections()
		_refresh_item_info()
	_close_context()

func _on_ctx_equip() -> void:
	if _context_entry != null and _context_entry.data is EquipmentData:
		_inventory.equip_from_entry(_context_entry)
		_selected_entry = null
		_clear_all_selections()
		_refresh_item_info()
	_close_context()

func _on_ctx_drop() -> void:
	if _context_entry != null:
		_inventory.drop_entry(_context_entry)
		_selected_entry = null
		_clear_all_selections()
		_refresh_item_info()
	_close_context()

func _close_context() -> void:
	context_menu.visible = false
	_context_entry = null
