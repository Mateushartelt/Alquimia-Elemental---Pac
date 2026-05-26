extends EnemyBase
## GolemEnxofre — Inimigo da Caldeira Vulcânica (Level 02).
## Fraco a H₂O (×2) e CO₂ (×2). Imune a SO₂ — absorve enxofre do magma.
## Dropa S ao morrer.

@onready var _sprite: Sprite2D = $Sprite2D

# spritesheet: 4 cols × 4 rows → frames 0-15
# 0-3  idle (linha 0)  |  4-7  walk (linha 1)  |  8-11 hurt (linha 2)  |  12-15 unused
const IDLE_FRAMES  := [0, 1, 2, 3]
const WALK_FRAMES  := [4, 5, 6, 7]
const HURT_FRAMES  := [8, 9, 10, 11]
const ANIM_FPS     := 8.0

var _anim_timer  : float = 0.0
var _anim_idx    : int   = 0
var _anim_frames : Array = IDLE_FRAMES

func _ready() -> void:
	max_health      = 40
	move_speed      = 30.0
	patrol_range    = 60.0
	damage_on_touch = 12
	element_drop    = "S"
	drop_amount     = 1
	weak_to         = ["H2O", "CO2"]
	immune_to       = ["SO2"]
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# choose animation set based on state
	var target_frames: Array
	match estate:
		EState.CHASE, EState.PATROL:
			target_frames = WALK_FRAMES if abs(velocity.x) > 1.0 else IDLE_FRAMES
		EState.HURT:
			target_frames = HURT_FRAMES
		_:
			target_frames = IDLE_FRAMES

	if target_frames != _anim_frames:
		_anim_frames = target_frames
		_anim_idx    = 0
		_anim_timer  = 0.0

	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_anim_idx = (_anim_idx + 1) % _anim_frames.size()
		_sprite.frame = _anim_frames[_anim_idx]

	_sprite.flip_h = not facing_right

	if _flash_timer > 0.0:
		var fa := clampf(_flash_timer / 0.15, 0.0, 1.0)
		_sprite.modulate = Color.WHITE.lerp(_flash_color, fa)
	else:
		_sprite.modulate = Color.WHITE

	queue_redraw()

func _draw() -> void:
	# HP bar only — body is drawn by Sprite2D
	if current_health <= 0:
		return
	var hp_r := float(current_health) / float(max_health)
	draw_rect(Rect2(-7.0, -13.0, 14.0, 2.0), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(-7.0, -13.0, 14.0 * hp_r, 2.0), Color(0.9, 0.35, 0.04, 1.0))

func _die() -> void:
	_spawn_death_label()
	super._die()

func _spawn_death_label() -> void:
	var lbl := Label.new()
	lbl.text = "S + H₂O → H₂SO₄!"
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.modulate = Color(1.0, 0.6, 0.0)
	lbl.position = global_position + Vector2(-32, -22)
	get_tree().current_scene.add_child(lbl)
	var tw := get_tree().current_scene.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 18, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)
