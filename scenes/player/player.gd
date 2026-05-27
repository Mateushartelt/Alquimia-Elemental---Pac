class_name Player
extends CharacterBody2D
## Player — Plataformer 2D com state machine + AnimationPlayer.

@export var walk_speed : float = 100.0
@export var jump_force : float = -320.0

const GRAVITY         := 900.0
const MAX_FALL        := 500.0
const COYOTE_TIME     := 0.12
const JUMP_BUFFER     := 0.12
const INVINCIBLE_TIME := 1.2
const HURT_DURATION   := 0.5
const WALL_SLIDE_SPEED := 50.0
const WALL_JUMP_VX     := 140.0
const WALL_JUMP_VY     := -300.0
const ATTACK_COOLDOWN  := 0.6

const PROJECTILE_SCENE := preload("res://scenes/player/projectile.tscn")

enum State { IDLE, WALK, JUMP, FALL, WALL_SLIDE, HURT, DEAD }
var _state := State.IDLE

var _coyote_timer    : float   = 0.0
var _jump_buffer     : float   = 0.0
var _was_on_floor    : bool    = false
var _facing_right    : bool    = true
var _invincible_timer: float   = 0.0
var _hurt_timer      : float   = 0.0
var _wall_normal     : Vector2 = Vector2.ZERO
var _attack_cooldown : float   = 0.0
var input_locked     : bool    = false

@onready var attack_point : Marker2D         = $AttackPoint
@onready var _anim        : AnimationPlayer  = $AnimationPlayer
@onready var _visual      : Node2D           = $Visual
@onready var _sprite      : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_build_animations()
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	_invincible_timer = maxf(0.0, _invincible_timer - delta)
	_tick_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal()
	_handle_jump()
	_handle_attack()
	move_and_slide()
	_update_coyote()
	_update_state()
	_update_visual()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var max_v := WALL_SLIDE_SPEED if _state == State.WALL_SLIDE else MAX_FALL
		velocity.y = minf(velocity.y + GRAVITY * delta, max_v)

func _handle_horizontal() -> void:
	if input_locked:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x    = dir * walk_speed
		_facing_right = dir > 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)

func _handle_jump() -> void:
	if input_locked:
		return
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	# Wall jump — tem prioridade sobre o pulo normal
	if _jump_buffer > 0.0 and _state == State.WALL_SLIDE:
		velocity.x    =  _wall_normal.x * WALL_JUMP_VX
		velocity.y    =  WALL_JUMP_VY
		_jump_buffer  =  0.0
		_coyote_timer =  0.0
		_set_state(State.JUMP)
		return
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y    = jump_force
		_jump_buffer  = 0.0
		_coyote_timer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

func _handle_attack() -> void:
	if input_locked:
		return
	if not Input.is_action_just_pressed("attack"):
		return
	if _attack_cooldown > 0.0:
		return
	if GameState.active_compound == "":
		return
	var proj: Area2D = PROJECTILE_SCENE.instantiate()
	proj.compound_id     = GameState.active_compound
	proj.direction       = Vector2.RIGHT if _facing_right else Vector2.LEFT
	proj.global_position = attack_point.global_position
	get_tree().current_scene.add_child(proj)
	_attack_cooldown = ATTACK_COOLDOWN
	attacked.emit(GameState.active_compound, proj.direction, attack_point.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_E:
		_try_special()
		return
	var num: int = event.physical_keycode - KEY_1
	if num >= 0 and num < GameState.discovered_compounds.size():
		GameState.set_active_compound(GameState.discovered_compounds[num])

func _try_special() -> void:
	if GameState.active_compound != "H2O":
		return
	if GameState.charge < GameState.charge_max:
		return
	var proj: Area2D = PROJECTILE_SCENE.instantiate()
	proj.compound_id     = "H2O"
	proj.is_special      = true
	proj.direction       = Vector2.RIGHT if _facing_right else Vector2.LEFT
	proj.global_position = attack_point.global_position
	get_tree().current_scene.add_child(proj)
	GameState.use_charge()

func _update_coyote() -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_timer = COYOTE_TIME
	_was_on_floor = is_on_floor()

func _tick_timers(delta: float) -> void:
	_coyote_timer    = maxf(0.0, _coyote_timer    - delta)
	_jump_buffer     = maxf(0.0, _jump_buffer     - delta)
	_hurt_timer      = maxf(0.0, _hurt_timer      - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

func _update_state() -> void:
	if _state == State.DEAD:
		return
	if _state == State.HURT and _hurt_timer > 0.0:
		return
	if input_locked:
		_set_state(State.FALL if not is_on_floor() else State.IDLE)
		return
	if is_on_floor():
		_wall_normal = Vector2.ZERO
		_set_state(State.IDLE if absf(velocity.x) < 5.0 else State.WALK)
	elif is_on_wall():
		var dir     := int(Input.get_axis("move_left", "move_right"))
		var wnormal := get_wall_normal()
		var into_w  := (dir > 0 and wnormal.x < 0) or (dir < 0 and wnormal.x > 0)
		if into_w:
			_wall_normal = wnormal
			_set_state(State.WALL_SLIDE)
		else:
			_wall_normal = Vector2.ZERO
			_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
	else:
		_wall_normal = Vector2.ZERO
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)

func _update_visual() -> void:
	_sprite.flip_h = not _facing_right
	var blink := _invincible_timer > 0.0 and int(_invincible_timer * 10) % 2 == 0
	var alpha := 0.0 if blink else 1.0
	if _state == State.WALL_SLIDE:
		_sprite.modulate = Color(0.55, 0.85, 1.0, alpha)
	else:
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)

func _set_state(s: State) -> void:
	if _state == s:
		return
	_state = s
	match s:
		State.IDLE:       _sprite.play("idle")
		State.WALK:       _sprite.play("walk")
		State.JUMP:       _sprite.play("jump")
		State.FALL:       _sprite.play("fall")
		State.WALL_SLIDE: _sprite.play("wall_slide")
		State.HURT:       _sprite.play("hurt")
		State.DEAD:       _sprite.play("dead")

func _build_animations() -> void:
	var lib := AnimationLibrary.new()

	# ── idle (loop 1.2s) ──────────────────────────────────────────────────
	var idle := Animation.new()
	idle.loop_mode = Animation.LOOP_LINEAR
	idle.length = 1.2
	var t: int = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(t, "Visual/Body:position:y")
	idle.track_insert_key(t, 0.0, -5.0)
	idle.track_insert_key(t, 0.6, -4.0)
	idle.track_insert_key(t, 1.2, -5.0)
	t = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(t, "Visual/Body:scale")
	idle.track_insert_key(t, 0.0, Vector2(1.0, 1.0))
	t = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(t, "Visual/LegLeft:position:y")
	idle.track_insert_key(t, 0.0, 5.0)
	t = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(t, "Visual/LegRight:position:y")
	idle.track_insert_key(t, 0.0, 5.0)
	lib.add_animation("idle", idle)

	# ── walk (loop 0.4s) ──────────────────────────────────────────────────
	var walk := Animation.new()
	walk.loop_mode = Animation.LOOP_LINEAR
	walk.length = 0.4
	t = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(t, "Visual/LegLeft:position:y")
	walk.track_insert_key(t, 0.0, -1.0)
	walk.track_insert_key(t, 0.2,  5.0)
	walk.track_insert_key(t, 0.4, -1.0)
	t = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(t, "Visual/LegRight:position:y")
	walk.track_insert_key(t, 0.0,  5.0)
	walk.track_insert_key(t, 0.2, -1.0)
	walk.track_insert_key(t, 0.4,  5.0)
	t = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(t, "Visual/Body:position:y")
	walk.track_insert_key(t, 0.0, -5.0)
	walk.track_insert_key(t, 0.2, -4.0)
	walk.track_insert_key(t, 0.4, -5.0)
	t = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(t, "Visual/Body:scale")
	walk.track_insert_key(t, 0.0, Vector2(1.0, 1.0))
	lib.add_animation("walk", walk)

	# ── jump (once 0.25s) ─────────────────────────────────────────────────
	var jump := Animation.new()
	jump.loop_mode = Animation.LOOP_NONE
	jump.length = 0.25
	t = jump.add_track(Animation.TYPE_VALUE)
	jump.track_set_path(t, "Visual/Body:scale")
	jump.track_insert_key(t, 0.0,  Vector2(1.0, 1.0))
	jump.track_insert_key(t, 0.1,  Vector2(1.2, 0.8))
	jump.track_insert_key(t, 0.25, Vector2(0.9, 1.2))
	t = jump.add_track(Animation.TYPE_VALUE)
	jump.track_set_path(t, "Visual/Head:position:y")
	jump.track_insert_key(t, 0.0,  -13.0)
	jump.track_insert_key(t, 0.1,  -15.0)
	jump.track_insert_key(t, 0.25, -14.0)
	lib.add_animation("jump", jump)

	# ── fall (loop 0.3s) ──────────────────────────────────────────────────
	var fall := Animation.new()
	fall.loop_mode = Animation.LOOP_LINEAR
	fall.length = 0.3
	t = fall.add_track(Animation.TYPE_VALUE)
	fall.track_set_path(t, "Visual/Body:scale")
	fall.track_insert_key(t, 0.0, Vector2(1.1, 0.9))
	fall.track_insert_key(t, 0.3, Vector2(1.0, 1.0))
	t = fall.add_track(Animation.TYPE_VALUE)
	fall.track_set_path(t, "Visual/LegLeft:position:y")
	fall.track_insert_key(t, 0.0, 5.0)
	t = fall.add_track(Animation.TYPE_VALUE)
	fall.track_set_path(t, "Visual/LegRight:position:y")
	fall.track_insert_key(t, 0.0, 5.0)
	lib.add_animation("fall", fall)

	# ── wall_slide (loop 0.5s) ────────────────────────────────────────────
	var wall_slide := Animation.new()
	wall_slide.loop_mode = Animation.LOOP_LINEAR
	wall_slide.length = 0.5
	t = wall_slide.add_track(Animation.TYPE_VALUE)
	wall_slide.track_set_path(t, "Visual/LegLeft:position:y")
	wall_slide.track_insert_key(t, 0.0, 8.0)
	wall_slide.track_insert_key(t, 0.5, 8.0)
	t = wall_slide.add_track(Animation.TYPE_VALUE)
	wall_slide.track_set_path(t, "Visual/LegRight:position:y")
	wall_slide.track_insert_key(t, 0.0, 8.0)
	wall_slide.track_insert_key(t, 0.5, 8.0)
	t = wall_slide.add_track(Animation.TYPE_VALUE)
	wall_slide.track_set_path(t, "Visual/Body:scale")
	wall_slide.track_insert_key(t, 0.0,  Vector2(0.85, 1.1))
	wall_slide.track_insert_key(t, 0.25, Vector2(0.88, 1.08))
	wall_slide.track_insert_key(t, 0.5,  Vector2(0.85, 1.1))
	lib.add_animation("wall_slide", wall_slide)

	# ── hurt (once 0.5s) ──────────────────────────────────────────────────
	var hurt := Animation.new()
	hurt.loop_mode = Animation.LOOP_NONE
	hurt.length = 0.5
	t = hurt.add_track(Animation.TYPE_VALUE)
	hurt.track_set_path(t, "Visual/Body:color")
	hurt.track_insert_key(t, 0.0, Color.WHITE)
	hurt.track_insert_key(t, 0.5, Color(0.227, 0.431, 0.667, 1.0))
	t = hurt.add_track(Animation.TYPE_VALUE)
	hurt.track_set_path(t, "Visual:position:x")
	hurt.track_insert_key(t, 0.0,   0.0)
	hurt.track_insert_key(t, 0.125, -3.0)
	hurt.track_insert_key(t, 0.25,  3.0)
	hurt.track_insert_key(t, 0.5,   0.0)
	lib.add_animation("hurt", hurt)

	# ── dead (once 0.6s) ──────────────────────────────────────────────────
	var dead_anim := Animation.new()
	dead_anim.loop_mode = Animation.LOOP_NONE
	dead_anim.length = 0.6
	t = dead_anim.add_track(Animation.TYPE_VALUE)
	dead_anim.track_set_path(t, "Visual:rotation_degrees")
	dead_anim.track_insert_key(t, 0.0, 0.0)
	dead_anim.track_insert_key(t, 0.6, 90.0)
	t = dead_anim.add_track(Animation.TYPE_VALUE)
	dead_anim.track_set_path(t, "Visual:modulate:a")
	dead_anim.track_insert_key(t, 0.0, 1.0)
	dead_anim.track_insert_key(t, 0.6, 0.0)
	lib.add_animation("dead", dead_anim)

	_anim.add_animation_library("", lib)

func reset_state() -> void:
	velocity          = Vector2.ZERO
	_invincible_timer = 0.0

func collect(element_id: String) -> void:
	GameState.collect_element(element_id)

func receive_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	if _invincible_timer > 0.0:
		return
	_invincible_timer = INVINCIBLE_TIME
	_hurt_timer = HURT_DURATION
	_set_state(State.HURT)
	GameState.take_damage(amount)

signal attacked(compound_id: String, direction: Vector2, origin: Vector2)
