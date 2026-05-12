extends EnemyBase
## GolemEnxofre — Inimigo da Caldeira Vulcânica (Level 02).
## Fraco a H₂O (×2) e CO₂ (×2). Imune a SO₂ — absorve enxofre do magma.
## Dropa S ao morrer.

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
	queue_redraw()

func _draw() -> void:
	var base  := Color(0.52, 0.26, 0.05)
	var lava  := Color(0.95, 0.40, 0.02)
	var dark  := Color(0.08, 0.04, 0.01)

	var fa  := clampf(_flash_timer / 0.15, 0.0, 1.0)
	var col := base.lerp(_flash_color if fa > 0.0 else base, fa)

	if not facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))

	var t     := Time.get_ticks_msec() * 0.001
	var pulse := sin(t * 1.8) * 0.3

	# ── Corpo rochoso / angular ───────────────────────────────────────────────
	draw_rect(Rect2(-5.0, -9.0, 10.0, 14.0), col)      # corpo central
	draw_rect(Rect2(-7.0, -5.0,  4.0,  7.0), col)      # ombro esq
	draw_rect(Rect2( 3.0, -5.0,  4.0,  7.0), col)      # ombro dir
	draw_rect(Rect2(-4.0,  5.0,  8.0,  4.0), col)      # base / pernas

	# Contorno escuro
	draw_rect(Rect2(-5.0, -9.0, 10.0, 14.0), dark, false, 0.8)

	# Fissuras de lava pulsando
	var lc := Color(lava.r, lava.g, lava.b, 0.65 + pulse)
	draw_line(Vector2(-2.0, -6.0), Vector2(-1.0, -1.0), lc, 1.2)
	draw_line(Vector2( 1.5, -7.0), Vector2( 2.5, -2.0), lc, 1.2)
	draw_line(Vector2(-3.0,  1.0), Vector2(-1.0,  4.0), lc, 1.0)
	draw_line(Vector2( 1.0,  0.0), Vector2( 3.0,  3.0), lc, 1.0)

	# ── Olhos — buracos de lava ───────────────────────────────────────────────
	var er := 1.3 if estate != EState.CHASE else 1.9
	var ec := Color(lava.r, lava.g, lava.b, 0.9 + pulse * 0.5)
	draw_circle(Vector2(-2.5, -5.5), er, ec)
	draw_circle(Vector2( 2.5, -5.5), er, ec)
	draw_circle(Vector2(-2.5, -5.5), er * 0.45, dark)
	draw_circle(Vector2( 2.5, -5.5), er * 0.45, dark)

	# ── Barra de HP ───────────────────────────────────────────────────────────
	var hp_r := float(current_health) / float(max_health)
	draw_rect(Rect2(-7.0, -13.0, 14.0, 2.0), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(-7.0, -13.0, 14.0 * hp_r, 2.0), Color(0.9, 0.35, 0.04, 1.0))

	if not facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
