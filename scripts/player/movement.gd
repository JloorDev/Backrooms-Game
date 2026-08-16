extends CharacterBody2D

const WALK_SPEED:   float = 45.0
const JOG_SPEED:    float = 65.0
const RUN_SPEED:    float = 90.0
const CROUCH_SPEED: float = 25.0
const ACCELERATION: float = 800.0
const FRICTION: float = 600.0

enum State { IDLE, WALK, JOG, RUN, CROUCH }
var state: State = State.IDLE
var is_crouching: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var stats:  StatsManager = $StatsManager
@onready var psm: Node = $PlayerStateManager

const SHAPE_STAND  := Vector2(10, 6)
const SHAPE_CROUCH := Vector2(10, 4)

var _sanity_effects: SanityEffects = null

func _ready() -> void:
	_set_collision_size(SHAPE_STAND)
	stats.set_inventory($InventoryManager)
	$HUD.init(stats, $InventoryManager, psm)

	var se = get_node_or_null("SanityEffects")
	if se:
		_sanity_effects = se
		stats.set_sanity_effects(se)

func set_sanity_effects(effects: SanityEffects) -> void:
	_sanity_effects = effects
	stats.set_sanity_effects(effects)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch"):
		is_crouching = !is_crouching

func _physics_process(delta: float) -> void:
	var dir: Vector2 = _get_input_dir()
	_update_state(dir)
	_apply_movement(delta, dir)
	_update_collision_shape()
	
	stats.set_movement_state(state)
	move_and_slide()

func _update_state(dir: Vector2) -> void:
	var moving: bool = dir.length() > 0.0

	if is_crouching:
		state = State.CROUCH
		return

	if not moving:
		state = State.IDLE
		return

	var wants_jog: bool = Input.is_action_pressed("jog")
	var wants_run: bool = Input.is_action_pressed("run")

	if wants_run and psm.can_run():
		state = State.RUN
	elif wants_jog and psm.can_jog():
		state = State.JOG
	else:
		state = State.WALK

func _apply_movement(delta: float, dir: Vector2) -> void:
	var magnitude: float = dir.length()
	var top_speed: float

	match state:
		State.RUN    : top_speed = RUN_SPEED
		State.JOG    : top_speed = JOG_SPEED
		State.CROUCH : top_speed = CROUCH_SPEED
		_            : top_speed = WALK_SPEED

	top_speed *= stats.get_speed_multiplier()

	if magnitude > 0.0:
		velocity = velocity.move_toward(
			dir.normalized() * top_speed * magnitude,
			ACCELERATION * delta
		)
		if abs(dir.x) > 0.1:
			sprite.flip_h = dir.x < 0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _update_collision_shape() -> void:
	if is_crouching:
		_set_collision_size(SHAPE_CROUCH)
	else:
		_set_collision_size(SHAPE_STAND)

func _set_collision_size(size: Vector2) -> void:
	if col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = size

func _get_input_dir() -> Vector2:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _sanity_effects:
		dir += _sanity_effects.get_input_noise()
	return dir.limit_length(1.0)

func get_state() -> State:
	return state
