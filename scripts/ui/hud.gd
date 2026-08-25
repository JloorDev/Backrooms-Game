extends CanvasLayer
class_name HUD

@onready var health_bar:  ProgressBar = $StatsPanel/VBoxContainer/HealthBar/ProgressBar
@onready var stamina_bar: ProgressBar = $StatsPanel/VBoxContainer/StaminaBar/ProgressBar
@onready var thirst_bar:  ProgressBar = $StatsPanel/VBoxContainer/ThirstBar/ProgressBar
@onready var hunger_bar:  ProgressBar = $StatsPanel/VBoxContainer/HungerBar/ProgressBar
@onready var sanity_bar:  ProgressBar = $StatsPanel/VBoxContainer/SanityBar/ProgressBar

@onready var stats_panel:     Panel        = $StatsPanel
@onready var inventory_panel: Panel        = $InventoryPanel
@onready var player_panel:    Panel        = $PlayerPanel
@onready var quick_bar:       HBoxContainer = $QuickBar
@onready var states_container: VBoxContainer = $PlayerPanel/ScrollContainer/StatesContainer

@onready var btn_stats:     Button = $QuickBar/BtnStats
@onready var btn_inventory: Button = $QuickBar/BtnInventory
@onready var btn_player:    Button = $QuickBar/BtnPlayer

@onready var grid:            GridContainer = $InventoryPanel/GridContainer
@onready var weight_label:    Label         = $InventoryPanel/WeightLabel
@onready var item_name_label: Label         = $InventoryPanel/ItemInfoPanel/ItemNameLabel
@onready var item_desc_label: Label         = $InventoryPanel/ItemInfoPanel/ItemDescLabel
@onready var item_stats_label: Label        = $InventoryPanel/ItemInfoPanel/ItemStatsLabel
@onready var use_button:      Button        = $InventoryPanel/ItemInfoPanel/UseButton
@onready var context_menu:    Panel         = $InventoryPanel/ContextMenu
@onready var ctx_use:         Button        = $InventoryPanel/ContextMenu/VBoxContainer/UseButton
@onready var ctx_drop:        Button        = $InventoryPanel/ContextMenu/VBoxContainer/DropButton

const COLOR_HIGH: Color = Color(0.20, 0.75, 0.25)
const COLOR_MID:  Color = Color(0.90, 0.70, 0.10)
const COLOR_LOW:  Color = Color(0.85, 0.25, 0.10)

var _target:  Dictionary = {"health":100.0,"stamina":100.0,"thirst":100.0,"hunger":100.0,"sanity":100.0}
var _current: Dictionary = {"health":100.0,"stamina":100.0,"thirst":100.0,"hunger":100.0,"sanity":100.0}
const SMOOTH_SPEED: float = 60.0

const ANIM_DURATION:  float = 0.25
const QUICKBAR_SHOWN_X:  float = 10.0
var   _quickbar_hidden_x: float = 0.0

var _quickbar_visible: bool  = true
var _quickbar_animating: bool = false
var _quickbar_tween: Tween   = null

var _stats:     StatsManager       = null
var _inventory: InventoryManager   = null
var _psm:       PlayerStateManager = null

var _selected_slot: int = -1
var _slot_nodes: Array[InventorySlot] = []
var _context_slot: int = -1

const SLOT_SCENE = preload("res://prefabs/ui/inventory_slot.tscn")

@onready var hotbar_container: HBoxContainer = $Hotbar

var _hotbar: HotbarManager = null
var _hotbar_slot_nodes: Array[InventorySlot] = []

func init(stats: StatsManager, inventory: InventoryManager, psm: PlayerStateManager = null, hotbar: HotbarManager = null) -> void:
	_stats     = stats
	_inventory = inventory
	_psm       = psm
	_hotbar    = hotbar
	_build_grid()
	_build_hotbar()
	_connect_signals()
	_refresh_all()

	stats_panel.visible    = false
	inventory_panel.visible = false
	player_panel.visible   = false

	quick_bar.position.x = QUICKBAR_SHOWN_X
	await get_tree().process_frame
	_quickbar_hidden_x = -(quick_bar.size.x + 20.0)

func _process(delta: float) -> void:
	_animate_bars(delta)

func _toggle_quickbar() -> void:
	if _quickbar_animating:
		return

	_quickbar_visible   = !_quickbar_visible
	_quickbar_animating = true

	if not _quickbar_visible:
		stats_panel.visible     = false
		inventory_panel.visible = false
		player_panel.visible    = false

	if _quickbar_tween and _quickbar_tween.is_valid():
		_quickbar_tween.kill()

	_quickbar_tween = create_tween()
	_quickbar_tween.set_ease(Tween.EASE_OUT)
	_quickbar_tween.set_trans(Tween.TRANS_CUBIC)

	var target_x = QUICKBAR_SHOWN_X if _quickbar_visible else _quickbar_hidden_x
	_quickbar_tween.tween_property(quick_bar, "position:x", target_x, ANIM_DURATION)
	await _quickbar_tween.finished
	_quickbar_animating = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_quickbar"):
		_toggle_quickbar()
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and context_menu.visible:
			_close_context()

func _toggle_stats() -> void:
	stats_panel.visible = !stats_panel.visible

func _toggle_inventory() -> void:
	inventory_panel.visible = !inventory_panel.visible
	_close_context()
	_selected_slot = -1
	_refresh_item_info()

func _toggle_player_panel() -> void:
	player_panel.visible = !player_panel.visible
	if player_panel.visible and _psm:
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
	use_button.pressed.connect(_on_use_pressed)
	ctx_use.pressed.connect(_on_ctx_use)
	ctx_drop.pressed.connect(_on_ctx_drop)
	btn_stats.pressed.connect(_toggle_stats)
	btn_inventory.pressed.connect(_toggle_inventory)
	btn_player.pressed.connect(_toggle_player_panel)
	if _psm:
		_psm.states_changed.connect(_on_states_changed)
	if _hotbar:
		_hotbar.hotbar_changed.connect(_refresh_hotbar)

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
	for child in grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for i in InventoryManager.SLOT_COUNT:
		var slot_node: InventorySlot = SLOT_SCENE.instantiate()
		grid.add_child(slot_node)
		slot_node.init(i, _inventory)
		slot_node.slot_selected.connect(_on_slot_pressed.bind(i))
		slot_node.slot_context_requested.connect(_on_context_requested)
		_slot_nodes.append(slot_node)

func _refresh_grid() -> void:
	for slot_node in _slot_nodes:
		slot_node.refresh()
		var flat: StyleBoxFlat = StyleBoxFlat.new()
		flat.bg_color = Color(0.3, 0.6, 1.0, 0.4) if slot_node.slot_index == _selected_slot \
			else Color(0.15, 0.15, 0.15, 0.6)
		flat.border_width_left   = 1
		flat.border_width_right  = 1
		flat.border_width_top    = 1
		flat.border_width_bottom = 1
		slot_node.add_theme_stylebox_override("panel", flat)

func _on_weight_changed(current: float, max_w: float) -> void:
	weight_label.text = "Peso: %.1f / %.1f kg" % [current, max_w]

func _on_slot_pressed(index: int) -> void:
	_selected_slot = index
	_refresh_grid()
	_refresh_item_info()

func _refresh_item_info() -> void:
	var slot = null
	if _selected_slot >= 0:
		slot = _inventory.get_slot(_selected_slot)
	if slot == null:
		item_name_label.text = ""
		item_desc_label.text = ""
		item_stats_label.text = ""
		use_button.visible   = false
		return
	item_name_label.text = slot.data.display_name
	item_desc_label.text = slot.data.description
	item_stats_label.text = "
".join(slot.data.get_stat_lines())
	use_button.visible   = slot.data is ConsumableData

func _on_use_pressed() -> void: _use_selected()

func _use_selected() -> void:
	if _selected_slot < 0: return
	var slot = _inventory.get_slot(_selected_slot)
	if slot == null: return
	if slot.data is ConsumableData:
		_stats.use_consumable(slot.data)
		_inventory.consume_item_at(_selected_slot)
		_refresh_item_info()

func _on_context_requested(index: int, global_pos: Vector2) -> void:
	_context_slot = index
	context_menu.global_position = global_pos
	context_menu.visible = true
	var slot = _inventory.get_slot(index)
	ctx_use.visible = slot != null and slot.data is ConsumableData

func _on_ctx_use() -> void:
	if _context_slot < 0: return
	var slot = _inventory.get_slot(_context_slot)
	if slot != null and slot.data is ConsumableData:
		_stats.use_consumable(slot.data)
		_inventory.consume_item_at(_context_slot)
		_refresh_item_info()
	_close_context()

func _on_ctx_drop() -> void:
	if _context_slot < 0: return
	_inventory.drop_item_at(_context_slot)
	_refresh_item_info()
	_close_context()

func _close_context() -> void:
	context_menu.visible = false
	_context_slot = -1
