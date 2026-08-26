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

@onready var grid_view:       ItemGridView  = $InventoryPanel/ItemGridView
@onready var weight_label:    Label         = $InventoryPanel/WeightLabel
@onready var item_name_label: Label         = $InventoryPanel/ItemInfoPanel/ItemNameLabel
@onready var item_desc_label: Label         = $InventoryPanel/ItemInfoPanel/ItemDescLabel
@onready var item_stats_label: Label        = $InventoryPanel/ItemInfoPanel/ItemStatsLabel
@onready var equipped_bag_icon:  TextureRect = $InventoryPanel/EquippedBagIcon
@onready var equipped_bag_label: Label       = $InventoryPanel/EquippedBagLabel
@onready var drop_bag_button:    Button      = $InventoryPanel/DropBagButton
@onready var use_button:      Button        = $InventoryPanel/ItemInfoPanel/UseButton
@onready var context_menu:    Panel         = $InventoryPanel/ContextMenu
@onready var ctx_use:         Button        = $InventoryPanel/ContextMenu/VBoxContainer/UseButton
@onready var ctx_drop:        Button        = $InventoryPanel/ContextMenu/VBoxContainer/DropButton
@onready var ctx_equip:       Button        = $InventoryPanel/ContextMenu/VBoxContainer/EquipButton

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

var _selected_entry: Variant = null
var _context_entry: Variant = null

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
	_refresh_equipped_bag()

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
	_selected_entry = null
	grid_view.set_selected(null)
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
	_inventory.weight_tier_changed.connect(_on_weight_tier_changed)
	_inventory.equipment_changed.connect(_refresh_equipped_bag)
	drop_bag_button.pressed.connect(_on_drop_bag_pressed)
	grid_view.item_selected.connect(_on_grid_item_selected)
	grid_view.item_context_requested.connect(_on_grid_item_context)
	grid_view.empty_clicked.connect(_on_grid_empty_clicked)
	use_button.pressed.connect(_on_use_pressed)
	ctx_use.pressed.connect(_on_ctx_use)
	ctx_drop.pressed.connect(_on_ctx_drop)
	ctx_equip.pressed.connect(_on_ctx_equip)
	btn_stats.pressed.connect(_toggle_stats)
	btn_inventory.pressed.connect(_toggle_inventory)
	btn_player.pressed.connect(_toggle_player_panel)
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
	else:
		equipped_bag_icon.texture = bag.data.icon
		equipped_bag_label.text = bag.data.display_name
		drop_bag_button.visible = true

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
	grid_view.init(_inventory)
	# TODO (Capa 3, paso 2): dibujar los items colocados encima de la grilla.

func _refresh_grid() -> void:
	grid_view.refresh()

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

func _on_grid_item_selected(entry: Dictionary) -> void:
	_selected_entry = entry
	grid_view.set_selected(entry)
	_refresh_item_info()

func _on_grid_empty_clicked() -> void:
	_selected_entry = null
	grid_view.set_selected(null)
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
		grid_view.set_selected(null)
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
		grid_view.set_selected(null)
		_refresh_item_info()
	_close_context()

func _on_ctx_equip() -> void:
	if _context_entry != null and _context_entry.data is EquipmentData:
		_inventory.equip_from_entry(_context_entry)
		_selected_entry = null
		grid_view.set_selected(null)
		_refresh_item_info()
	_close_context()

func _on_ctx_drop() -> void:
	if _context_entry != null:
		_inventory.drop_entry(_context_entry)
		_selected_entry = null
		grid_view.set_selected(null)
		_refresh_item_info()
	_close_context()

func _close_context() -> void:
	context_menu.visible = false
	_context_entry = null
