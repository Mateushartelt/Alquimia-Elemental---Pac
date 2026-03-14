class_name Player
extends CharacterBody2D
## Player — Plataformer 2D com visual procedural via _draw().

@export var walk_speed : float = 100.0
@export var jump_force : float = -320.0

const GRAVITY         := 900.0
const MAX_FALL        := 500.0
const COYOTE_TIME     := 0.12
const JUMP_BUFFER     := 0.12
const INVINCIBLE_TIME := 1.2

const PROJECTILE_SCENE := preload("res://scenes/player/projectile.tscn")

var _coyote_timer    : float = 0.0
var _jump_buffer     : float = 0.0
var _was_on_floor    : bool  = false
var _facing_right    : bool  = true
var _invincible_timer: float = 0.0
var _draw_visible    : bool  = true

@onready var attack_point: Marker2D = $AttackPoint

func _physics_process(delta: float) -> void:
	_invincible_timer = maxf(0.0, _invincible_timer - delta)
	_tick_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal()
	_handle_jump()
	_handle_attack()
	move_and_slide()
	_update_coyote()
	_update_visual()
	queue_redraw()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

func _handle_horizontal() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x    = dir * walk_speed
		_facing_right = dir > 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y    = jump_force
		_jump_buffer  = 0.0
		_coyote_timer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

func _handle_attack() -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	if GameState.active_compound == "":
		return
	var proj: Area2D = PROJECTILE_SCENE.instantiate()
	proj.compound_id     = GameState.active_compound
	proj.direction       = Vector2.RIGHT if _facing_right else Vector2.LEFT
	proj.global_position = attack_point.global_position
	get_tree().current_scene.add_child(proj)

func _update_coyote() -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_timer = COYOTE_TIME
	_was_on_floor = is_on_floor()

func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_jump_buffer  = maxf(0.0, _jump_buffer  - delta)

func _update_visual() -> void:
	_draw_visible = not (_invincible_timer > 0.0 and int(_invincible_timer * 10) % 2 == 0)

func _draw() -> void:
	# Blink de invencibilidade — early return ANTES de qualquer transform
	if not _draw_visible:
		return

	if not _facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))

	# Cor do corpo por estado
	var col: Color
	if _invincible_timer > 0.0:
		col = Color.WHITE
	elif is_on_floor():
		col = Color(0.2, 0.6, 1.0) if absf(velocity.x) < 5.0 else Color(0.2, 0.9, 0.4)
	elif velocity.y < 0.0:
		col = Color(1.0, 0.9, 0.2)
	else:
		col = Color(1.0, 0.5, 0.1)

	var dark  := Color(0.05, 0.08, 0.15)
	var light := Color(1.0, 1.0, 1.0, 0.5)

	# ── Pernas (atrás do torso) ────────────────────────────────────────────
	var la := 0.0  # leg animation offset
	if is_on_floor() and absf(velocity.x) > 5.0:
		la = sin(Time.get_ticks_msec() * 0.001 * 12.0) * 0.8
	# Perna esquerda (la positivo = desce, negativo = sobe)
	draw_rect(Rect2(-4.0, 6.0 + la,  3.0, 2.0), col)
	# Perna direita (fase oposta)
	draw_rect(Rect2( 1.0, 6.0 - la,  3.0, 2.0), col)
	draw_rect(Rect2(-4.0, 6.0 + la,  3.0, 2.0), dark, false, 0.5)
	draw_rect(Rect2( 1.0, 6.0 - la,  3.0, 2.0), dark, false, 0.5)

	# ── Torso ─────────────────────────────────────────────────────────────
	draw_rect(Rect2(-4.0, 0.0, 8.0, 6.0), col)
	draw_rect(Rect2(-4.0, 0.0, 8.0, 6.0), dark, false, 0.5)
	draw_rect(Rect2(-4.0, 0.0, 3.0, 1.5), light)  # highlight

	# ── Pescoço ───────────────────────────────────────────────────────────
	draw_rect(Rect2(-1.0, -2.0, 2.0, 2.0), col)

	# ── Cabeça ────────────────────────────────────────────────────────────
	draw_circle(Vector2(0.0, -5.5), 3.0, col)
	draw_arc(Vector2(0.0, -5.5), 3.0, 0.0, TAU, 16, dark, 0.5)
	draw_circle(Vector2(-1.2, -7.0), 1.0, light)  # reflexo

	# ── Olho (lado direito quando facing right) ────────────────────────────
	draw_rect(Rect2(0.5, -6.5, 1.5, 1.5), dark)

	# ── Reseta transform ───────────────────────────────────────────────────
	if not _facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func reset_state() -> void:
	velocity          = Vector2.ZERO
	_invincible_timer = 0.0

func collect(element_id: String) -> void:
	GameState.collect_element(element_id)

func receive_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	if _invincible_timer > 0.0:
		return
	_invincible_timer = INVINCIBLE_TIME
	GameState.take_damage(amount)

signal attacked(compound_id: String, direction: Vector2, origin: Vector2)
