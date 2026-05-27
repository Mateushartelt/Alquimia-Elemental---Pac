extends EnemyBase
## GolemEnxofre — Inimigo da Caldeira Vulcânica (Level 02).
## Fraco a H₂O (×2) e CO₂ (×2). Imune a SO₂ — absorve enxofre do magma.
## Dropa S ao morrer.

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _dying := false

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
	_sprite.play("walk")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not _dying:
		_sprite.play("walk")

	_sprite.flip_h = not facing_right

	if _flash_timer > 0.0:
		var fa := clampf(_flash_timer / 0.15, 0.0, 1.0)
		_sprite.modulate = Color.WHITE.lerp(_flash_color, fa)
	else:
		_sprite.modulate = Color.WHITE

	queue_redraw()

func _draw() -> void:
	if current_health <= 0:
		return
	var hp_r := float(current_health) / float(max_health)
	draw_rect(Rect2(-7.0, -13.0, 14.0, 2.0), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(-7.0, -13.0, 14.0 * hp_r, 2.0), Color(0.9, 0.35, 0.04, 1.0))

func _die() -> void:
	_dying = true
	_sprite.play("death")
	_spawn_death_label()
	var tw := create_tween()
	tw.tween_interval(4.0 / 8.0)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	await tw.finished
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
