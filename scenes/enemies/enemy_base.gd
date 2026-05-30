class_name EnemyBase
extends CharacterBody2D
## EnemyBase — Classe base para todos os inimigos.
## Visual procedural: subclasses implementam _draw() e leem _flash_color/_flash_timer.

@export var max_health: int      = 30
@export var move_speed: float    = 40.0
@export var patrol_range: float  = 48.0
@export var damage_on_touch: int = 10
@export var element_drop: String = ""
@export var drop_amount: int     = 1
@export var weak_to: Array[String] = []
@export var immune_to: Array[String] = []

enum EState { PATROL, CHASE, HURT, DEAD }
var estate: EState = EState.PATROL

var current_health: int
var origin_position: Vector2
var facing_right := true
var hurt_timer   := 0.0

# Flash visual — subclasses leem em _draw()
var _flash_color: Color = Color.TRANSPARENT
var _flash_timer: float = 0.0

# sprite opcional para retrocompatibilidade (null se o nó não existir)
var sprite: ColorRect = null

# Y local da barra de vida (acima da cabeça) — subclasses ajustam por sprite
var hp_bar_y: float = -20.0

@onready var detect_area: Area2D = $DetectArea

signal died(enemy: Node)

const PICKUP_SCENE = preload("res://scenes/world/element_pickup.tscn")

func _ready() -> void:
	current_health  = max_health
	origin_position = global_position
	sprite = get_node_or_null("Sprite") as ColorRect
	if detect_area:
		detect_area.body_entered.connect(_on_player_detected)
		detect_area.body_exited.connect(_on_player_left)

func _physics_process(delta: float) -> void:
	hurt_timer = max(0.0, hurt_timer - delta)
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _flash_timer <= 0.0:
			_flash_color = Color.TRANSPARENT
	match estate:
		EState.PATROL: _patrol(delta)
		EState.CHASE:  _chase(delta)
		EState.HURT:
			velocity.x = move_toward(velocity.x, 0, move_speed * 4)
			if hurt_timer <= 0:
				estate = EState.PATROL
		EState.DEAD: pass
	if estate != EState.DEAD:
		velocity.y += 900.0 * delta
		velocity.y  = min(velocity.y, 500.0)
	move_and_slide()
	_check_player_touch()
	queue_redraw()

## Barra de vida desenhada acima da cabeça de TODOS os inimigos.
func _draw() -> void:
	if current_health <= 0 or estate == EState.DEAD:
		return
	var hp_r := clampf(float(current_health) / float(max_health), 0.0, 1.0)
	const W := 16.0
	draw_rect(Rect2(-W * 0.5, hp_bar_y, W, 2.5), Color(0.1, 0.1, 0.1, 0.85))
	var fill := Color(0.2, 0.85, 0.25) if hp_r > 0.5 else (Color(1.0, 0.7, 0.0) if hp_r > 0.25 else Color(0.95, 0.2, 0.15))
	draw_rect(Rect2(-W * 0.5, hp_bar_y, W * hp_r, 2.5), fill)

func _patrol(delta: float) -> void:
	velocity.x = move_speed * (1.0 if facing_right else -1.0)
	var dist := global_position.x - origin_position.x
	if dist > patrol_range or (is_on_wall() and facing_right):
		facing_right = false
	elif dist < -patrol_range or (is_on_wall() and not facing_right):
		facing_right = true

func _chase(_delta: float) -> void:
	_patrol(_delta)

func _check_player_touch() -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < 14.0:
			if p.has_method("receive_damage"):
				var dir: Vector2 = (p.global_position - global_position).normalized()
				p.receive_damage(damage_on_touch, dir)

func take_damage(amount: int, compound_id: String = "") -> void:
	if estate == EState.DEAD:
		return
	if compound_id in immune_to:
		_show_immune()
		return
	var final_damage := amount
	if compound_id in weak_to:
		final_damage = int(amount * 2.0)
		_show_weakness()
	current_health -= final_damage
	hurt_timer      = 0.3
	estate          = EState.HURT
	velocity.x      = -200.0 * (1.0 if facing_right else -1.0)
	velocity.y      = -80.0
	if current_health <= 0:
		_die()

func _die() -> void:
	estate = EState.DEAD
	died.emit(self)
	_drop_element()
	queue_free()

func _drop_element() -> void:
	if element_drop == "":
		return
	var pickup: Area2D = PICKUP_SCENE.instantiate()
	pickup.element_id      = element_drop
	pickup.global_position = global_position + Vector2(0, -22)   # acima do chão
	get_tree().current_scene.add_child(pickup)

func _on_player_detected(body: Node) -> void:
	if body.is_in_group("player"):
		estate = EState.CHASE

func _on_player_left(body: Node) -> void:
	if body.is_in_group("player"):
		estate = EState.PATROL

func _show_immune() -> void:
	_flash_color = Color.WHITE
	_flash_timer = 0.15

func _show_weakness() -> void:
	_flash_color = Color.YELLOW
	_flash_timer = 0.15
