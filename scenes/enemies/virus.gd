extends EnemyBase
## Virus — Inimigo do Nível 3 (Complexo Subaquático).
## Fraco a Etanol (dano duplo) e HCl, imune a H2O, dropa C ao morrer.

func _ready() -> void:
	max_health      = 18
	move_speed      = 58.0
	patrol_range    = 64.0
	damage_on_touch = 10
	element_drop    = "C"
	drop_amount     = 1
	weak_to         = ["Etanol", "HCl"]
	immune_to       = ["H2O"]
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()

func _draw() -> void:
	var base  := Color(0.54, 0.0, 1.0, 1.0)
	var fa    := clampf(_flash_timer / 0.15, 0.0, 1.0)
	var col   := base.lerp(_flash_color if fa > 0.0 else base, fa)
	var dark  := Color(0.2, 0.0, 0.4, 1.0)
	var spike := col.lightened(0.25)

	var pulse  := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.15
	var radius := 8.0 * pulse

	# ── Corpo central ────────────────────────────────────────────────────────
	draw_circle(Vector2.ZERO, radius, col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, dark, 0.8)

	# ── Espículas proteicas (8 spikes giratórios) ─────────────────────────────
	for i: int in 8:
		var angle := (TAU / 8.0) * i + Time.get_ticks_msec() * 0.0008
		var tip   := Vector2(cos(angle), sin(angle)) * (radius + 5.0)
		var lv    := Vector2(cos(angle + 0.3), sin(angle + 0.3)) * radius * 0.8
		var rv    := Vector2(cos(angle - 0.3), sin(angle - 0.3)) * radius * 0.8
		draw_colored_polygon([lv, tip, rv], spike)

	# ── Olhos ────────────────────────────────────────────────────────────────
	draw_circle(Vector2(-3.0, -2.0), 1.5, Color.RED)
	draw_circle(Vector2( 3.0, -2.0), 1.5, Color.RED)
	draw_circle(Vector2(-2.5, -2.5), 0.5, Color.WHITE)
	draw_circle(Vector2( 3.5, -2.5), 0.5, Color.WHITE)

	# ── HP bar ───────────────────────────────────────────────────────────────
	var hp_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(-7.0, -16.0, 14.0, 2.0), Color(0.15, 0.15, 0.15, 0.8))
	draw_rect(Rect2(-7.0, -16.0, 14.0 * hp_ratio, 2.0), Color(0.9, 0.15, 0.15, 1.0))

func _die() -> void:
	_spawn_curiosity_label()
	super._die()

func _spawn_curiosity_label() -> void:
	var lbl := Label.new()
	lbl.text = "Proteínas desnaturadas!"
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.modulate = Color(0.8, 0.4, 1.0)
	lbl.position = global_position + Vector2(-40, -20)
	get_tree().current_scene.add_child(lbl)
	var tween := get_tree().current_scene.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 18, 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
