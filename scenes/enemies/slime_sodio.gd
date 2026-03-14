extends EnemyBase
## SlimeSodio — Inimigo básico do Nível 1.
## Fraco a H₂O (dano duplo), imune a NaCl, dropa Na ao morrer.

func _ready() -> void:
	max_health      = 25
	move_speed      = 35.0
	patrol_range    = 56.0
	damage_on_touch = 8
	element_drop    = "Na"
	drop_amount     = 2
	weak_to         = ["H2O"]
	immune_to       = ["NaCl"]
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()

func _draw() -> void:
	# Cor base
	var base := Color(1.0, 0.70, 0.10, 1.0)
	# Mistura flash (imunidade = branco, fraqueza = amarelo)
	var fa := clampf(_flash_timer / 0.15, 0.0, 1.0)
	var col := base.lerp(_flash_color if fa > 0.0 else base, fa)
	var dark  := Color(0.15, 0.08, 0.0, 1.0)
	var shine := Color(1.0, 1.0, 0.6, 0.45)

	if not facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))

	# Squash quando idle no chão
	var bw := 5.0
	var by := 0.5  # centro vertical levemente abaixo
	if is_on_floor() and absf(velocity.x) < 2.0:
		var pulse := sin(Time.get_ticks_msec() * 0.001 * 2.0) * 0.4
		bw = 5.0 + pulse

	# ── Corpo blob (dois rects ortogonais + círculo central) ──────────────
	draw_rect(Rect2(-bw, by - 2.0, bw * 2.0, 4.0), col)          # faixa horizontal
	draw_rect(Rect2(-bw * 0.7, by - 4.0, bw * 1.4, 8.0), col)    # faixa vertical
	draw_circle(Vector2(0.0, by), bw * 0.85, col)                  # centro redondo
	# Base plana (fundo do slime toca o chão)
	draw_rect(Rect2(-bw, by + 3.0, bw * 2.0, 2.0), col)

	# Contorno
	draw_arc(Vector2(0.0, by), bw * 0.95, 0.0, TAU, 24, dark, 0.75)

	# Destaque
	draw_circle(Vector2(-bw * 0.4, by - bw * 0.55), bw * 0.22, shine)

	# ── Olhos ─────────────────────────────────────────────────────────────
	var er := 1.1 if estate != EState.CHASE else 1.5
	draw_circle(Vector2(-2.0, by - 1.5), er, dark)
	draw_circle(Vector2( 2.0, by - 1.5), er, dark)
	draw_circle(Vector2(-1.5, by - 2.0), 0.4, Color.WHITE)
	draw_circle(Vector2( 2.5, by - 2.0), 0.4, Color.WHITE)

	# ── Boca ──────────────────────────────────────────────────────────────
	if estate == EState.CHASE:
		draw_arc(Vector2(0.0, by + 1.0), 2.0, 0.0, PI, 8, dark, 1.0)
	else:
		draw_arc(Vector2(0.0, by + 0.5), 1.5, 0.3, PI - 0.3, 8, dark, 0.75)

	# ── HP bar ────────────────────────────────────────────────────────────
	var hp_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(-7.0, -8.0, 14.0, 2.0), Color(0.15, 0.15, 0.15, 0.8))
	draw_rect(Rect2(-7.0, -8.0, 14.0 * hp_ratio, 2.0), Color(0.9, 0.15, 0.15, 1.0))

	if not facing_right:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _die() -> void:
	_spawn_curiosity_label()
	super._die()

func _spawn_curiosity_label() -> void:
	var lbl := Label.new()
	lbl.text = "Na + H₂O → explosão!"
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.modulate = Color(1, 1, 0)
	lbl.position = global_position + Vector2(-24, -20)
	get_tree().current_scene.add_child(lbl)
	var tween := get_tree().current_scene.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 18, 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
